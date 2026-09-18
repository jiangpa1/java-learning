$enc=[System.Text.Encoding]::UTF8
$SECRET=[Environment]::GetEnvironmentVariable('JWT_SECRET','User')

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
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=20}
  if($Tok){ $p.Headers=@{Authorization="Bearer $Tok"} }
  if($Json){ $p.ContentType='application/json; charset=utf-8'; $p.Body=$enc.GetBytes($Json) }
  $body=''; $code=-1; $lim=$null; $rem=$null
  try { $r=Invoke-WebRequest @p
        $code=$r.StatusCode
        $body=[System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
        $lim=$r.Headers['X-RateLimit-Limit']; $rem=$r.Headers['X-RateLimit-Remaining']
  } catch { $resp=$_.Exception.Response
        if($resp){ $code=[int]$resp.StatusCode
          $sr=New-Object System.IO.StreamReader($resp.GetResponseStream(),[System.Text.Encoding]::UTF8); $body=$sr.ReadToEnd() }
        else { $body=$_.Exception.Message } }
  New-Object psobject -Property @{ Http=$code; Body=$body; Limit=$lim; Rem=$rem } }
function BizCode { param([string]$b) if($b -match '"code"\s*:\s*(-?\d+)'){ return [int]$Matches[1] } return $null }

function B64UrlEnc { param([byte[]]$b) [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }
function New-Hmac { param([string]$S) New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (,[System.Text.Encoding]::UTF8.GetBytes($S)) }
function New-Token { param([long]$Uid,[string]$Name,[int]$Role)
  $n=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $hdr='{"alg":"HS256","typ":"JWT"}'
  $pl='{"id":'+$Uid+',"username":"'+$Name+'","type":"access","role":'+$Role+',"sub":"'+$Uid+'","jti":"'+[guid]::NewGuid().ToString()+'","iss":"learning","iat":'+$n+',"exp":'+($n+1800)+'}'
  $h=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($hdr))
  $p=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($pl))
  $sig=B64UrlEnc ((New-Hmac $SECRET).ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$h.$p")))
  return "$h.$p.$sig" }

$tokUser  = New-Token 18 'zhangsan' 0
$tokAdmin = New-Token 17 'lisi' 1

Write-Host "=== A. POST /auth/login (was 500) ===" -ForegroundColor Cyan
$r = Hit 'POST' '/auth/login' '{"username":"lisi","password":"123456"}' ''
Write-Host "  bizCode=$(BizCode $r.Body)   (expect 200)"
$liveTok = if($r.Body -match '"accessToken":"([^"]+)"'){ $Matches[1] } else { $null }
Write-Host "  real token acquired = $([bool]$liveTok)"

Write-Host "`n=== B. authenticated dimensions use userId ===" -ForegroundColor Cyan
$r = Hit 'GET' '/article/3' '' $tokUser
Write-Host "  GET /article/3 (user 18)  bizCode=$(BizCode $r.Body)"
Write-Host "  keys for user 18:" 
Write-Host "    $(RRedis @('KEYS','learning:limit:user:18:*'))"

Write-Host "`n=== C. order check (doc 9.2 item 4): do 403 requests consume quota? ===" -ForegroundColor Cyan
$K = 'learning:limit:user:18:/user/list'
Write-Host "  DEL test key -> $(RRedis @('DEL',$K))"
Write-Host "  getUser 18 calling GET /user/list (admin-only, will 403) x6 ..."
$codes=@()
for($i=1;$i -le 6;$i++){
  $r = Hit 'GET' '/user/list' '' $tokUser
  $codes += (BizCode $r.Body)
}
Write-Host "  bizCodes: $($codes -join ',')   (expect all 403)"
$zcard = RRedis @('ZCARD',$K)
Write-Host "  ZCARD of $K"
Write-Host "    -> $zcard"
Write-Host "  VERDICT: $(if($zcard -match ':0'){'PASS - authorisation rejected BEFORE rate limiting, no quota consumed'}else{'FAIL - 403 requests consumed rate-limit quota (limiter is registered before the authz interceptor)'})"
Write-Host "  cleanup DEL -> $(RRedis @('DEL',$K))"

Write-Host "`n=== D. admin path still fine ===" -ForegroundColor Cyan
$r = Hit 'GET' '/user/list' '' $tokAdmin
Write-Host "  admin GET /user/list     bizCode=$(BizCode $r.Body)"

Write-Host "`n=== E. remaining limit keys (informational) ===" -ForegroundColor Cyan
Write-Host "  $(RRedis @('KEYS','learning:limit*'))"
