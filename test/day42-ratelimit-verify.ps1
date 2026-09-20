$enc=[System.Text.Encoding]::UTF8

function RRedis { param([string[]]$Cmd)
  $c=New-Object System.Net.Sockets.TcpClient
  $iar=$c.BeginConnect('192.168.133.128',6379,$null,$null)
  if(-not $iar.AsyncWaitHandle.WaitOne(3000)){ $c.Close(); return 'CONNECT_TIMEOUT' }
  $c.EndConnect($iar); $s=$c.GetStream(); $s.ReadTimeout=3000; $s.WriteTimeout=3000
  $e=[System.Text.Encoding]::UTF8
  function SendIt($st,$parts){ $sb=New-Object System.Text.StringBuilder; [void]$sb.Append("*$($parts.Count)`r`n")
    foreach($x in $parts){ [void]$sb.Append("`$$($e.GetByteCount($x))`r`n$x`r`n") }
    $b=$e.GetBytes($sb.ToString()); $st.Write($b,0,$b.Length); $st.Flush() }
  try { SendIt $s @('AUTH',$env:LEARNING_DB_PASS); Start-Sleep -Milliseconds 120
        $s.Read((New-Object byte[] 256),0,256) | Out-Null
        SendIt $s $Cmd; Start-Sleep -Milliseconds 200
        $buf=New-Object byte[] 65536; $n=$s.Read($buf,0,$buf.Length); $out=$e.GetString($buf,0,$n)
  } catch { $out="ERR: $($_.Exception.Message)" }
  $c.Close(); return $out.Trim() }

function Hit { param([string]$Method,[string]$Path,[string]$Json,[string]$Tok)
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=15}
  if($Tok){ $p.Headers=@{Authorization="Bearer $Tok"} }
  if($Json){ $p.ContentType='application/json; charset=utf-8'; $p.Body=$enc.GetBytes($Json) }
  $body=''; $code=-1; $lim=$null; $rem=$null; $ra=$null
  try { $r=Invoke-WebRequest @p
        $code=$r.StatusCode
        $body=[System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
        $lim=$r.Headers['X-RateLimit-Limit']; $rem=$r.Headers['X-RateLimit-Remaining']; $ra=$r.Headers['Retry-After']
  } catch { $resp=$_.Exception.Response
        if($resp){ $code=[int]$resp.StatusCode
          $sr=New-Object System.IO.StreamReader($resp.GetResponseStream(),[System.Text.Encoding]::UTF8); $body=$sr.ReadToEnd() }
        else { $body=$_.Exception.Message } }
  New-Object psobject -Property @{ Http=$code; Body=$body; Limit=$lim; Rem=$rem; RetryAfter=$ra } }
function BizCode { param([string]$b) if($b -match '"code"\s*:\s*(-?\d+)'){ return [int]$Matches[1] } return $null }

$K='learning:limit:ip:127.0.0.1:/auth/register'
Write-Host "=== reset the register counter to start clean ===" -ForegroundColor Cyan
Write-Host "  DEL -> $(RRedis @('DEL',$K))"
Write-Host "  ZCARD before -> $(RRedis @('ZCARD',$K))"

Write-Host "`n=== register x8 (threshold = 5/min) ===" -ForegroundColor Cyan
$codes=@()
for($i=1;$i -le 8;$i++){
  $r = Hit 'POST' '/auth/register' ('{"username":"rlv' + $i + '","password":"123456"}') ''
  $bc = BizCode $r.Body
  $codes += $bc
  $msg=''
  if($r.Body -match '"message"\s*:\s*"([^"]*)"'){ $msg=$Matches[1] }
  Write-Host ("  #{0} bizCode={1,-4} limit={2,-4} remaining={3,-4} retryAfter={4,-4} {5}" -f $i,$bc,$r.Limit,$r.Rem,$r.RetryAfter,$msg)
}

Write-Host "`n=== ZSET state ===" -ForegroundColor Cyan
Write-Host "  ZCARD -> $(RRedis @('ZCARD',$K))   (members are now unique: timestamp-random)"
Write-Host "  TTL   -> $(RRedis @('TTL',$K))"
Write-Host "  first 3 members:"
Write-Host (RRedis @('ZRANGE',$K,'0','2'))

Write-Host "`n=== verdict ===" -ForegroundColor Cyan
$ok = ($codes[0..4] -notcontains 429) -and ($codes[5..7] -contains 429)
Write-Host ("  calls 1-5 should pass, calls 6-8 should be 429  =>  {0}" -f $(if($ok){'PASS'}else{'FAIL'}))

Write-Host "`n=== cleanup ===" -ForegroundColor Cyan
$MYSQL='C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
$CNF=Join-Path $env:TEMP 'rt4.cnf'
@"
[client]
host=192.168.133.128
port=3306
user=root
password=$env:LEARNING_DB_PASS
"@ | Set-Content $CNF -Encoding ASCII
"DELETE FROM tb_user WHERE username LIKE 'rlv%';" | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -N -B learning 2>$null
Write-Host "  DEL limit key -> $(RRedis @('DEL',$K))"
"SELECT id,username,role FROM tb_user ORDER BY id;" | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -t learning 2>$null
