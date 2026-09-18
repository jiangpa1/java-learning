$enc=[System.Text.Encoding]::UTF8

function Hit { param([string]$Method,[string]$Path,[string]$Json,[string]$Tok)
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=20}
  if($Tok){ $p.Headers=@{Authorization="Bearer $Tok"} }
  if($Json){ $p.ContentType='application/json; charset=utf-8'; $p.Body=$enc.GetBytes($Json) }
  $body=''; $code=-1
  try { $r=Invoke-WebRequest @p
        $code=$r.StatusCode
        $body=[System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
  } catch { $resp=$_.Exception.Response
        if($resp){ $code=[int]$resp.StatusCode
          $sr=New-Object System.IO.StreamReader($resp.GetResponseStream(),[System.Text.Encoding]::UTF8); $body=$sr.ReadToEnd() }
        else { $body=$_.Exception.Message } }
  New-Object psobject -Property @{ Http=$code; Body=$body } }
function BizCode { param([string]$b) if($b -match '"code"\s*:\s*(-?\d+)'){ return [int]$Matches[1] } return $null }
function Msg { param([string]$b) if($b -match '"message"\s*:\s*"([^"]*)"'){ return $Matches[1] } return '' }
function Fld { param($b,$n) if($b -match ('"'+$n+'"\s*:\s*"([^"]+)"')){ return $Matches[1] } return $null }

Write-Host "=== NORMAL PATH REGRESSION (redis back on 6379) ===" -ForegroundColor Cyan

Write-Host "`n[1] login must work again"
$r = Hit 'POST' '/auth/login' '{"username":"lisi","password":"123456"}' ''
$tok = Fld $r.Body 'accessToken'
$rt  = Fld $r.Body 'refreshToken'
Write-Host "  bizCode=$(BizCode $r.Body)  msg=$(Msg $r.Body)  accessLen=$($tok.Length) refreshLen=$($rt.Length)"

Write-Host "`n[2] the 5xx that appeared while Redis was down"
$r = Hit 'GET' '/article/3' '' $tok
Write-Host "  GET /article/3     bizCode=$(BizCode $r.Body)  (was 500 while redis down)"
$r = Hit 'POST' '/auth/logout' '' $tok
Write-Host "  POST /auth/logout  bizCode=$(BizCode $r.Body)  (was 500 while redis down)"

Write-Host "`n[3] refresh still works end to end"
$r2 = Hit 'POST' '/auth/login' '{"username":"lisi","password":"123456"}' ''
$rt2 = Fld $r2.Body 'refreshToken'
$r = Hit 'POST' '/auth/refresh' ('{"refreshToken":"' + $rt2 + '"}') ''
Write-Host "  POST /auth/refresh bizCode=$(BizCode $r.Body)  newAccessLen=$((Fld $r.Body 'accessToken').Length)"

Write-Host "`n[4] rate limiting still alive after the change"
$K='learning:limit:ip:127.0.0.1:/auth/register'
Write-Host "  (register threshold 5/min; will use unique names)"
$codes=@()
for($i=1;$i -le 7;$i++){
  $r = Hit 'POST' '/auth/register' ('{"username":"nrm' + $i + '","password":"123456"}') ''
  $codes += (BizCode $r.Body)
}
Write-Host "  register x7 bizCodes: $($codes -join ',')"
Write-Host "  VERDICT: $(if(($codes[5] -eq 429) -or ($codes[6] -eq 429)){'PASS - limiter still enforces (429 appeared)'}else{'CHECK - no 429 (key may have leftover state)'})"

Write-Host "`n[5] cleanup test users"
$MYSQL='C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
$CNF=Join-Path $env:TEMP 'rn.cnf'
@"
[client]
host=192.168.133.128
port=3306
user=root
password=$env:LEARNING_DB_PASS
"@ | Set-Content $CNF -Encoding ASCII
"DELETE FROM tb_user WHERE username LIKE 'nrm%' OR username LIKE 'foa%';" | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -N -B learning 2>$null
Write-Host "  removed nrm%/foa% test users"
"SELECT id,username,role FROM tb_user ORDER BY id;" | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -t learning 2>$null
