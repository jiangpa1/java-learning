$enc=[System.Text.Encoding]::UTF8
$SECRET=[Environment]::GetEnvironmentVariable('JWT_SECRET','User')

function Hit { param([string]$Method,[string]$Path,[string]$Json,[string]$Tok)
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=40}
  if($Tok){ $p.Headers=@{Authorization="Bearer $Tok"} }
  if($Json){ $p.ContentType='application/json; charset=utf-8'; $p.Body=$enc.GetBytes($Json) }
  $body=''; $code=-1
  $t0=Get-Date
  try { $r=Invoke-WebRequest @p
        $code=$r.StatusCode
        $body=[System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
  } catch { $resp=$_.Exception.Response
        if($resp){ $code=[int]$resp.StatusCode
          $sr=New-Object System.IO.StreamReader($resp.GetResponseStream(),[System.Text.Encoding]::UTF8); $body=$sr.ReadToEnd() }
        else { $body=$_.Exception.Message } }
  $ms=[int]((Get-Date)-$t0).TotalMilliseconds
  New-Object psobject -Property @{ Http=$code; Body=$body; Ms=$ms } }
function BizCode { param([string]$b) if($b -match '"code"\s*:\s*(-?\d+)'){ return [int]$Matches[1] } return $null }
function Msg { param([string]$b) if($b -match '"message"\s*:\s*"([^"]*)"'){ return $Matches[1] } return '' }
$script:P=0; $script:F=0
function Expect { param($label,$got,$want,$body,$ms)
  $ok = ($got -eq $want)
  if($ok){ $script:P++; Write-Host ("  [PASS] {0,-46} bizCode={1,-5} {2}ms" -f $label,$got,$ms) -ForegroundColor Green }
  else { $script:F++; Write-Host ("  [FAIL] {0,-46} bizCode={1,-5} expected={2} {3}ms" -f $label,$got,$want,$ms) -ForegroundColor Red }
  $m = Msg $body
  if($m){ Write-Host "         msg: $m" -ForegroundColor DarkGray } }

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
$tok = New-Token 18 'zhangsan' 0

Write-Host "=== DEGRADED PATH (spring.redis.port=9999, Redis unreachable) ===" -ForegroundColor Cyan
Write-Host "design: cache/limiter fail-OPEN, blacklist+refresh-key fail-CLOSED(503)" -ForegroundColor DarkGray

Write-Host "`n[1] fail-CLOSED: refresh-key WRITE (issue) -> 503" -ForegroundColor White
$r = Hit 'POST' '/auth/login' '{"username":"lisi","password":"123456"}' ''
Expect 'POST /auth/login' (BizCode $r.Body) 503 $r.Body $r.Ms

Write-Host "`n[2] fail-CLOSED: blacklist READ (isRevoked) -> 503" -ForegroundColor White
$r = Hit 'GET' '/article/3' '' $tok
Expect 'GET /article/3 (valid token)' (BizCode $r.Body) 503 $r.Body $r.Ms
$r = Hit 'GET' '/article/list?pageNum=1&pageSize=5' '' $tok
Expect 'GET /article/list (valid token)' (BizCode $r.Body) 503 $r.Body $r.Ms

Write-Host "`n[3] fail-CLOSED: blacklist WRITE (logout) -> 503  <-- the fix under test" -ForegroundColor White
$r = Hit 'POST' '/auth/logout' '' $tok
Expect 'POST /auth/logout (valid token)' (BizCode $r.Body) 503 $r.Body $r.Ms
if((BizCode $r.Body) -eq 200){ Write-Host "         !! fail-OPEN: logout claimed success but the token was NOT blacklisted" -ForegroundColor Yellow }

Write-Host "`n[4] fail-CLOSED: refresh-key READ (refresh) -> 503" -ForegroundColor White
$rt = New-Token 18 'zhangsan' 0
$r = Hit 'POST' '/auth/refresh' ('{"refreshToken":"' + $rt + '"}') ''
Write-Host "  (using an access-type token so it fails the type check before touching Redis)"
Expect 'POST /auth/refresh (type-mismatched token)' (BizCode $r.Body) 401 $r.Body $r.Ms
$refreshTok = New-Token 18 'zhangsan' 0
# build a proper refresh-type token
$n=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$hdr='{"alg":"HS256","typ":"JWT"}'
$pl='{"id":18,"username":"zhangsan","type":"refresh","sub":"18","jti":"'+[guid]::NewGuid().ToString()+'","iss":"learning","iat":'+$n+',"exp":'+($n+604800)+'}'
$h=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($hdr))
$p=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($pl))
$sig=B64UrlEnc ((New-Hmac $SECRET).ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$h.$p")))
$realRefresh="$h.$p.$sig"
$r = Hit 'POST' '/auth/refresh' ('{"refreshToken":"' + $realRefresh + '"}') ''
Expect 'POST /auth/refresh (valid refresh token)' (BizCode $r.Body) 503 $r.Body $r.Ms

Write-Host "`n[5] fail-OPEN: rate limiter must NOT block (register x7, limit 5)" -ForegroundColor White
$codes=@()
for($i=1;$i -le 7;$i++){
  $r = Hit 'POST' '/auth/register' ('{"username":"deg' + $i + '","password":"123456"}') ''
  $codes += (BizCode $r.Body)
}
Write-Host "  register x7 bizCodes: $($codes -join ',')"
if($codes -notcontains 429 -and $codes -notcontains 500){
  $script:P++; Write-Host "  [PASS] limiter failed OPEN - no 429, no 500" -ForegroundColor Green
} else {
  $script:F++; Write-Host "  [FAIL] limiter misbehaved: $($codes -join ',')" -ForegroundColor Red
}

Write-Host "`n[6] no-token path must stay 401 and be FAST (no Redis round trip)" -ForegroundColor White
$r = Hit 'GET' '/article/3' '' ''
Expect 'GET /article/3 (no token)' (BizCode $r.Body) 401 $r.Body $r.Ms

Write-Host "`n[7] @RateLimit endpoint not touching Redis elsewhere: cache fail-open" -ForegroundColor White
$r = Hit 'GET' '/category/list' '' ''
Expect 'GET /category/list (no token)' (BizCode $r.Body) 401 $r.Body $r.Ms

Write-Host ""
Write-Host ("RESULT : PASS={0}  FAIL={1}" -f $script:P,$script:F) -ForegroundColor $(if($script:F -eq 0){'Green'}else{'Yellow'})

Write-Host "`n[cleanup] remove deg% test users"
$MYSQL='C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
$CNF=Join-Path $env:TEMP 'rd.cnf'
@"
[client]
host=192.168.133.128
port=3306
user=root
password=$env:LEARNING_DB_PASS
"@ | Set-Content $CNF -Encoding ASCII
"DELETE FROM tb_user WHERE username LIKE 'deg%';" | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -N -B learning 2>$null
"SELECT id,username,role FROM tb_user ORDER BY id;" | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -t learning 2>$null
