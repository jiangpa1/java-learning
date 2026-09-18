$SECRET=[Environment]::GetEnvironmentVariable('JWT_SECRET','User')
$MYSQL='C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
$CNF=Join-Path $env:TEMP 'rj.cnf'
@"
[client]
host=192.168.133.128
port=3306
user=root
password=$env:LEARNING_DB_PASS
"@ | Set-Content $CNF -Encoding ASCII
function RunSql { param([string]$s) $t=Join-Path $env:TEMP 'rj.txt'
  ((($s | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -N -B learning 2>$t)) -join "").Trim() }

function Call { param([string]$Method,[string]$Path,$Obj,[string]$Token)
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=20}
  if($Token){ $p.Headers=@{Authorization="Bearer $Token"} }
  if($Obj){ $p.ContentType='application/json; charset=utf-8'; $p.Body=[System.Text.Encoding]::UTF8.GetBytes(($Obj|ConvertTo-Json -Compress)) }
  try{ $r=Invoke-WebRequest @p; return [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) }
  catch{ $resp=$_.Exception.Response
    if($resp){ $sr=New-Object System.IO.StreamReader($resp.GetResponseStream(),[System.Text.Encoding]::UTF8); return $sr.ReadToEnd() }
    return "ERR: $($_.Exception.Message)" } }
function Code { param($b)
  if($b -match '"code"\s*:\s*(-?\d+)'){ return [int]$Matches[1] }
  if($b -match '"status"\s*:\s*(\d+)'){ return [int]$Matches[1] }
  return $null }
function Fld { param($b,$n) if($b -match ('"'+$n+'"\s*:\s*"([^"]+)"')){ $Matches[1] } else { $null } }
function B64UrlEnc { param([byte[]]$b) [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }
function New-Hmac { param([string]$S) New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (,[System.Text.Encoding]::UTF8.GetBytes($S)) }
function New-Jwt { param([long]$Exp,[string]$Type,[long]$Uid,[string]$Name)
  $now=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $hdr='{"alg":"HS256","typ":"JWT"}'
  $pl='{"id":'+$Uid+',"username":"'+$Name+'","type":"'+$Type+'","sub":"'+$Uid+'","jti":"'+[guid]::NewGuid().ToString()+'","iss":"learning","iat":'+$now+',"exp":'+$Exp+'}'
  $h=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($hdr))
  $p=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($pl))
  $sig=B64UrlEnc ((New-Hmac $SECRET).ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$h.$p")))
  return "$h.$p.$sig" }

$ok=0;$ng=0
function T { param($cond,$desc,$detail)
  if($cond){ $script:ok++; Write-Host "  [PASS] $desc" -ForegroundColor Green }
  else { $script:ng++; Write-Host "  [FAIL] $desc" -ForegroundColor Red; if($detail){ Write-Host "         -> $detail" -ForegroundColor DarkGray } } }
function Info { param($m) Write-Host "         ($m)" -ForegroundColor DarkGray }
function Head { param($m) Write-Host "`n$m" -ForegroundColor White }

$uid = RunSql "SELECT id FROM tb_user WHERE username='zhangsan';"
Write-Host "===== refresh() JWT exception handling (the 500 -> 401 fix) =====" -ForegroundColor Cyan
Info "JWT_SECRET len=$($SECRET.Length)  zhangsan id=$uid"

$r = Call POST '/auth/login' @{username='zhangsan';password='123456'}
$rt = Fld $r 'refreshToken'
Info "login code=$(Code $r) refreshTokenLen=$($rt.Length)"

Head "[1] control: a VALID refresh token still works"
$r = Call POST '/auth/refresh' @{refreshToken=$rt}
T ((Code $r) -eq 200) "valid refresh -> 200" "code=$(Code $r) body=$r"
$rt2 = Fld $r 'refreshToken'

Head "[2] garbage string  (was 500)"
$r = Call POST '/auth/refresh' @{refreshToken='this-is-not-a-jwt'}
T ((Code $r) -eq 401) "garbage -> 401" "code=$(Code $r) body=$r"
T ($r -notmatch '"code":\s*500') "not 500 any more" $r

Head "[3] tampered signature  (was 500)"
$parts = $rt2.Split('.')
$bad = "$($parts[0]).$($parts[1]).$($parts[2].Substring(0,10))AAAA"
$r = Call POST '/auth/refresh' @{refreshToken=$bad}
T ((Code $r) -eq 401) "tampered sig -> 401" "code=$(Code $r) body=$r"

Head "[4] unparseable payload  (was 500)"
$r = Call POST '/auth/refresh' @{refreshToken="$($parts[0]).@@@@.$($parts[2])"}
T ((Code $r) -eq 401) "broken payload -> 401" "code=$(Code $r) body=$r"

Head "[5] ★ REAL EXPIRED token, signed with the project secret  (was 500)"
$now=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$expired = New-Jwt ($now-60) 'refresh' ([long]$uid) 'zhangsan'
Info "expired token len=$($expired.Length)"
$r = Call POST '/auth/refresh' @{refreshToken=$expired}
T ((Code $r) -eq 401) "expired refresh -> 401" "code=$(Code $r) body=$r"
Info "message tells the user what to do: $(Fld $r 'message')"

Head "[6] access token sent to refresh (type check still works)"
$r = Call POST '/auth/login' @{username='zhangsan';password='123456'}
$at = Fld $r 'accessToken'
$r = Call POST '/auth/refresh' @{refreshToken=$at}
T ((Code $r) -eq 401) "access token at /auth/refresh -> 401" "code=$(Code $r) body=$r"

Head "[7] validation still intact"
$r = Call POST '/auth/refresh' @{}
T ((Code $r) -eq 400) "missing field -> 400" "code=$(Code $r) body=$r"
$r = Call POST '/auth/refresh' @{refreshToken=''}
T ((Code $r) -eq 400) "empty -> 400" "code=$(Code $r) body=$r"

Head "[8] regression: interceptor still rejects refreshToken at business endpoints"
$r = Call POST '/auth/login' @{username='zhangsan';password='123456'}
$rt3 = Fld $r 'refreshToken'
$r = Call GET '/article/list?pageNum=1&pageSize=5' $null $rt3
T ((Code $r) -eq 401) "refreshToken on business API -> 401" "code=$(Code $r) body=$r"
$r = Call GET '/article/list?pageNum=1&pageSize=5' $null 'garbage'
T ((Code $r) -eq 401) "garbage token on business API -> 401" "code=$(Code $r) body=$r"

Head "[9] logout boundary unchanged (expired access token still logs out = 200)"
$expiredAccess = New-Jwt ($now-60) 'access' ([long]$uid) 'zhangsan'
$r = Call POST '/auth/logout' $null $expiredAccess
T ((Code $r) -eq 200) "logout with expired access -> 200" "code=$(Code $r) body=$r"

Write-Host ""
Write-Host ("RESULT : PASS={0}  FAIL={1}" -f $ok,$ng) -ForegroundColor $(if($ng -eq 0){'Green'}else{'Yellow'})
