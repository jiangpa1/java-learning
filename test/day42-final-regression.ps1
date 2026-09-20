$enc=[System.Text.Encoding]::UTF8
$SECRET=[Environment]::GetEnvironmentVariable('JWT_SECRET','User')
$MYSQL='C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
$CNF=Join-Path $env:TEMP 'reg.cnf'
@"
[client]
host=192.168.133.128
port=3306
user=root
password=$env:LEARNING_DB_PASS
"@ | Set-Content $CNF -Encoding ASCII
function RunSql { param([string]$s) $t=Join-Path $env:TEMP 'reg.txt'
  ((($s | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -N -B learning 2>$t)) -join "").Trim() }

function RRedis { param([string[]]$Cmd)
  $c=New-Object System.Net.Sockets.TcpClient
  $iar=$c.BeginConnect('192.168.133.128',6379,$null,$null)
  if(-not $iar.AsyncWaitHandle.WaitOne(3000)){ $c.Close(); return 'TIMEOUT' }
  $c.EndConnect($iar); $s=$c.GetStream(); $s.ReadTimeout=3000; $s.WriteTimeout=3000
  $e=[System.Text.Encoding]::UTF8
  function SendIt($st,$parts){ $sb=New-Object System.Text.StringBuilder; [void]$sb.Append("*$($parts.Count)`r`n")
    foreach($x in $parts){ [void]$sb.Append("`$$($e.GetByteCount($x))`r`n$x`r`n") }
    $b=$e.GetBytes($sb.ToString()); $st.Write($b,0,$b.Length); $st.Flush() }
  try { SendIt $s @('AUTH',$env:LEARNING_DB_PASS); Start-Sleep -Milliseconds 120
        $s.Read((New-Object byte[] 256),0,256) | Out-Null
        SendIt $s $Cmd; Start-Sleep -Milliseconds 200
    $buf=New-Object byte[] 65536; $n=$s.Read($buf,0,$buf.Length); $out=$e.GetString($buf,0,$n)
  } catch { $out="ERR" }
  $c.Close(); return $out.Trim() }
function RNum { param([string[]]$Cmd) $r=RRedis $Cmd; if($r -match '^:(-?\d+)'){return [int]$Matches[1]}; return $r }

function Hit { param([string]$Method,[string]$Path,[string]$Json,[string]$Tok)
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=25}
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
function Fld { param($b,$n) if($b -match ('"'+$n+'"\s*:\s*"([^"]+)"')){ return $Matches[1] } return $null }
$script:n=0; $script:ok2=0
function T { param($label,$got,$want)
  $script:n++
  if($got -eq $want){ $script:ok2++; Write-Host ("  [PASS] {0,-48} {1}" -f $label,$got) -ForegroundColor Green }
  else { Write-Host ("  [FAIL] {0,-48} got={1} want={2}" -f $label,$got,$want) -ForegroundColor Red } }

function B64UrlEnc { param([byte[]]$b) [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }
function New-Hmac { param([string]$S) New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (,[System.Text.Encoding]::UTF8.GetBytes($S)) }
function New-Tok { param([long]$Uid,[string]$N,[int]$R,[string]$Typ)
  $t=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $hdr='{"alg":"HS256","typ":"JWT"}'
  $pl='{"id":'+$Uid+',"username":"'+$N+'","type":"'+$Typ+'","role":'+$R+',"sub":"'+$Uid+'","jti":"'+[guid]::NewGuid().ToString()+'","iss":"learning","iat":'+$t+',"exp":'+($t+1800)+'}'
  $h=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($hdr)); $p=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($pl))
  $sig=B64UrlEnc ((New-Hmac $SECRET).ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$h.$p")))
  return "$h.$p.$sig" }
$tokUser=New-Tok 18 'zhangsan' 0 'access'
$tokAdmin=New-Tok 17 'lisi' 1 'access'

Write-Host "=== FINAL FULL REGRESSION (redis=6379 running) ===" -ForegroundColor Cyan

Write-Host "`n[1] auth flow" -ForegroundColor White
$r = Hit 'POST' '/auth/login' '{"username":"lisi","password":"123456"}' ''
T 'POST /auth/login' (BizCode $r.Body) 200
$liveTok = Fld $r.Body 'accessToken'; $liveRt = Fld $r.Body 'refreshToken'
$r = Hit 'POST' '/auth/refresh' ('{"refreshToken":"' + $liveRt + '"}') ''
T 'POST /auth/refresh' (BizCode $r.Body) 200
$r = Hit 'POST' '/auth/logout' '' $liveTok
T 'POST /auth/logout' (BizCode $r.Body) 200
$r = Hit 'GET' '/article/3' '' $liveTok
T 'GET /article/3 with logged-out token' (BizCode $r.Body) 401

Write-Host "`n[2] rate limiting still enforcing" -ForegroundColor White
$codes=@()
for($i=1;$i -le 7;$i++){ $codes += (BizCode (Hit 'POST' '/auth/register' ('{"username":"fin' + $i + '","password":"123456"}') '').Body) }
Write-Host "  register x7 -> $($codes -join ',')"
T 'limiter triggers 429 after 5' (($codes | Where-Object {$_ -eq 429}).Count -gt 0) $true

Write-Host "`n[3] role / authorisation" -ForegroundColor White
T 'ADMIN GET /user/list'    (BizCode (Hit 'GET' '/user/list' '' $tokAdmin).Body) 200
T 'USER  GET /user/list'    (BizCode (Hit 'GET' '/user/list' '' $tokUser).Body) 403
T 'USER  GET /user/18 (self)' (BizCode (Hit 'GET' '/user/18' '' $tokUser).Body) 200
T 'USER  GET /user/17 (other)' (BizCode (Hit 'GET' '/user/17' '' $tokUser).Body) 403
T 'USER  promote self'      (BizCode (Hit 'PUT' '/user/role' '{"id":18,"role":1}' $tokUser).Body) 403

Write-Host "`n[4] category admin-only" -ForegroundColor White
T 'USER  POST /category'    (BizCode (Hit 'POST' '/category' '{"name":"fin_cat"}' $tokUser).Body) 403
T 'ADMIN POST /category'    (BizCode (Hit 'POST' '/category' '{"name":"fin_cat"}' $tokAdmin).Body) 200

Write-Host "`n[5] logical delete + cache eviction" -ForegroundColor White
$r = Hit 'POST' '/article' '{"title":"final-reg","content":"body for cache"}' $tokAdmin
$aid = $null; if($r.Body -match '"data"\s*:\s*(\d+)'){ $aid=[int]$Matches[1] }
Write-Host "  created article id=$aid"
$null = Hit 'GET' "/article/$aid" '' $tokAdmin
$null = Hit 'GET' "/article/$aid" '' $tokAdmin
$kD="learning:article:detail:$aid"
T 'cache key exists after 2 reads' (RNum @('EXISTS',$kD)) 1
$r = Hit 'DELETE' "/article/$aid" '' $tokAdmin
T 'DELETE /article/{id}' (BizCode $r.Body) 200
T 'article row deleted=1 in DB' (RunSql "SELECT deleted FROM tb_article WHERE id=$aid;") '1'
T 'cache key evicted' (RNum @('EXISTS',$kD)) 0
T 'deleted article -> 404' (BizCode (Hit 'GET' "/article/$aid" '' $tokAdmin).Body) 404

Write-Host "`n[6] rate-limit headers on normal responses" -ForegroundColor White
$r = Hit 'GET' '/user/list' '' $tokAdmin
$r = Hit 'GET' '/user/list' '' $tokAdmin
Write-Host "  X-RateLimit-Limit=$($r.Limit)  Remaining=$($r.Rem)"
if($r.Limit){ $script:n++; $script:ok2++; Write-Host "  [PASS] headers present on success" -ForegroundColor Green }
else { Write-Host "  [FAIL] no X-RateLimit headers on success" -ForegroundColor Red; $script:n++ }

Write-Host "`n[7] interceptor order: 403 requests must not consume quota" -ForegroundColor White
$K='learning:limit:user:18:/user/list'
$null = RRedis @('DEL',$K)
for($i=1;$i -le 5;$i++){ $null = Hit 'GET' '/user/list' '' $tokUser }
T 'no quota consumed by 403s (ZCARD=0)' (RNum @('ZCARD',$K)) 0

Write-Host "`n[cleanup]" -ForegroundColor White
RunSql "DELETE FROM tb_user WHERE username LIKE 'fin%';" | Out-Null
RunSql "DELETE FROM tb_category WHERE name='fin_cat';" | Out-Null
RunSql "DELETE FROM tb_article WHERE id=$aid;" | Out-Null
"  users: " + (RunSql "SELECT GROUP_CONCAT(username) FROM tb_user;")
"  articles: " + (RunSql "SELECT GROUP_CONCAT(id) FROM tb_article;")
"  categories: " + (RunSql "SELECT GROUP_CONCAT(name) FROM tb_category;")

Write-Host ""
Write-Host ("RESULT : {0}/{1} passed" -f $script:ok2,$script:n) -ForegroundColor $(if($script:ok2 -eq $script:n){'Green'}else{'Yellow'})
