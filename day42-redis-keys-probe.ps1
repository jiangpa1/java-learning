$enc=[System.Text.Encoding]::UTF8
$SECRET=[Environment]::GetEnvironmentVariable('JWT_SECRET','User')

function B64UrlEnc { param([byte[]]$b) [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }
function New-Hmac { param([string]$S) New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (,[System.Text.Encoding]::UTF8.GetBytes($S)) }
$now=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$hdr='{"alg":"HS256","typ":"JWT"}'
$pl='{"id":18,"username":"zhangsan","type":"access","role":0,"sub":"18","jti":"'+[guid]::NewGuid().ToString()+'","iss":"learning","iat":'+$now+',"exp":'+($now+1800)+'}'
$h=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($hdr))
$p=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($pl))
$sig=B64UrlEnc ((New-Hmac $SECRET).ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$h.$p")))
$tok="$h.$p.$sig"

# --- redis with read timeout so it can never hang ---
function RRedis {
  param([string[]]$Cmd)
  $c=New-Object System.Net.Sockets.TcpClient
  $iar=$c.BeginConnect('192.168.133.128',6379,$null,$null)
  if(-not $iar.AsyncWaitHandle.WaitOne(3000)){ $c.Close(); return 'CONNECT_TIMEOUT' }
  $c.EndConnect($iar)
  $s=$c.GetStream(); $s.ReadTimeout=3000; $s.WriteTimeout=3000
  $e=[System.Text.Encoding]::UTF8
  function SendIt($st,$parts){
    $sb=New-Object System.Text.StringBuilder
    [void]$sb.Append("*$($parts.Count)`r`n")
    foreach($x in $parts){ [void]$sb.Append("`$$($e.GetByteCount($x))`r`n$x`r`n") }
    $b=$e.GetBytes($sb.ToString()); $st.Write($b,0,$b.Length); $st.Flush()
  }
  try {
    SendIt $s @('AUTH',$env:LEARNING_DB_PASS); Start-Sleep -Milliseconds 120
    $s.Read((New-Object byte[] 256),0,256) | Out-Null
    SendIt $s $Cmd; Start-Sleep -Milliseconds 250
    $buf=New-Object byte[] 8192; $n=$s.Read($buf,0,$buf.Length)
    $out=$e.GetString($buf,0,$n)
  } catch { $out="REDIS_READ_ERR: $($_.Exception.Message)" }
  $c.Close()
  return $out.Trim()
}

Write-Host "redis connectivity: $(RRedis @('PING'))" -ForegroundColor DarkGray
Write-Host "keys BEFORE:"
Write-Host "  $(RRedis @('KEYS','learning:limit*'))"

Write-Host "`ncalling a @RateLimit endpoint 3 times (GET /article/3) ..."
for($i=1;$i -le 3;$i++){
  $r=Invoke-WebRequest -Uri 'http://127.0.0.1:8080/article/3' -Method GET -UseBasicParsing -TimeoutSec 15 -Headers @{Authorization="Bearer $tok"}
  $b=[System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
  $bc = if($b -match '"code"\s*:\s*(\d+)'){ $Matches[1] } else { '?' }
  Write-Host "  call #$i -> bizCode=$bc"
}

Write-Host "`nkeys AFTER:"
Write-Host "  $(RRedis @('KEYS','learning:limit*'))"
Write-Host "`nNOTE: if no learning:limit* key exists, the Lua script never ran -> the failure is at execute() time, not inside the script."
