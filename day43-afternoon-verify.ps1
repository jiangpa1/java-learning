$enc=[System.Text.Encoding]::UTF8
$SECRET=[Environment]::GetEnvironmentVariable('JWT_SECRET','User')

function Hit { param([string]$Method,[string]$Path,[string]$RawBody,[string]$Tok,[string]$CType)
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=20}
  $h=@{}
  if($Tok){ $h['Authorization']="Bearer $Tok" }
  if($CType){ $h['Content-Type']=$CType }
  if($h.Count -gt 0){ $p.Headers=$h }
  if($RawBody -ne $null -and $RawBody -ne ''){
    if(-not $CType){ $p.ContentType='application/json; charset=utf-8' }
    $p.Body=$enc.GetBytes($RawBody)
  }
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
function Fld { param([string]$b,[string]$n) if($b -match ('"'+$n+'"\s*:\s*"([^"]*)"')){ return $Matches[1] } return '' }
$script:n=0; $script:ok=0
function T { param($label,$got,$want)
  $script:n++
  if($got -eq $want){ $script:ok++; Write-Host ("  [PASS] {0,-50} {1}" -f $label,$got) -ForegroundColor Green }
  else { Write-Host ("  [FAIL] {0,-50} got={1} want={2}" -f $label,$got,$want) -ForegroundColor Red } }

function B64UrlEnc { param([byte[]]$b) [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }
function New-Hmac { param([string]$S) New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (,[System.Text.Encoding]::UTF8.GetBytes($S)) }
function New-Tok { param([long]$Uid,[string]$N,[int]$R)
  $t=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $hdr='{"alg":"HS256","typ":"JWT"}'
  $pl='{"id":'+$Uid+',"username":"'+$N+'","type":"access","role":'+$R+',"sub":"'+$Uid+'","jti":"'+[guid]::NewGuid().ToString()+'","iss":"learning","iat":'+$t+',"exp":'+($t+1800)+'}'
  $h=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($hdr))
  $p=B64UrlEnc ([System.Text.Encoding]::UTF8.GetBytes($pl))
  $sig=B64UrlEnc ((New-Hmac $SECRET).ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$h.$p")))
  return "$h.$p.$sig" }

$tokAdmin=New-Tok 17 'lisi' 1
$tokUser=New-Tok 18 'zhangsan' 0
$nl=[char]10

Write-Host "=== A. user list pagination ===" -ForegroundColor Cyan
$r = Hit 'GET' '/user/list?pageNum=1&pageSize=2' $null $tokAdmin
T 'GET /user/list?pageSize=2 -> code' (BizCode $r.Body) 200
Write-Host ("       body: " + $r.Body)
T 'has total field'    ($r.Body -match '"total"')   $true
T 'has pageNum field'  ($r.Body -match '"pageNum"') $true
T 'has records field'  ($r.Body -match '"records"') $true
$cnt = ([regex]::Matches($r.Body,'"id":')).Count
Write-Host "       ids in records = $cnt (pageSize=2 -> expect 2)"
T 'pageSize honoured (2 rows)' $cnt 2

$r = Hit 'GET' '/user/list?pageNum=1&pageSize=999' $null $tokAdmin
T 'pageSize=999 clamped, no error' (BizCode $r.Body) 200

$r = Hit 'GET' '/user/list' $null $tokUser
T 'normal user still 403' (BizCode $r.Body) 403

$r = Hit 'GET' '/user/list?pageNum=99&pageSize=10' $null $tokAdmin
T 'out-of-range page -> 200 empty' (BizCode $r.Body) 200

Write-Host "$nl=== B. body parse exception -> 400 (was 500) ===" -ForegroundColor Cyan
$r = Hit 'POST' '/auth/login' '{"username":"lisi",' $null
T 'truncated JSON -> 400' (BizCode $r.Body) 400
Write-Host ("       msg: " + (Fld $r.Body 'message'))

$r = Hit 'POST' '/auth/login' 'not-json-at-all' $null
T 'non-JSON -> 400' (BizCode $r.Body) 400

$r = Hit 'POST' '/auth/login' '{"username":"lisi","password":"123456"}' $null 'text/plain'
T 'Content-Type text/plain -> 400' (BizCode $r.Body) 400
Write-Host ("       msg: " + (Fld $r.Body 'message'))

$r = Hit 'POST' '/auth/login' '{"username":"lisi","password":"123456"}' $null
T 'valid JSON still 200 (no regression)' (BizCode $r.Body) 200

Write-Host "$nl=== C. article category validation ===" -ForegroundColor Cyan
$r = Hit 'POST' '/article' '{"title":"cat-test","content":"x","categoryId":999999}' $tokAdmin
T 'categoryId=999999 -> 404' (BizCode $r.Body) 404
Write-Host ("       msg: " + (Fld $r.Body 'message'))

$r = Hit 'GET' '/category/list' $null $tokAdmin
$cid = $null
if($r.Body -match '"id":(\d+)'){ $cid=[int]$Matches[1] }
Write-Host "       real category id = $cid"
$r = Hit 'POST' '/article' ('{"title":"cat-ok","content":"x","categoryId":' + $cid + '}') $tokAdmin
T 'categoryId=real -> 200' (BizCode $r.Body) 200
$newAid = $null
if($r.Body -match '"data":(\d+)'){ $newAid=[int]$Matches[1] }

Write-Host "$nl=== C2. what if categoryId is ABSENT? ===" -ForegroundColor Cyan
$r = Hit 'POST' '/article' '{"title":"no-cat","content":"x"}' $tokAdmin
Write-Host ("       absent categoryId -> code=" + (BizCode $r.Body) + " msg=" + (Fld $r.Body 'message'))

Write-Host "$nl=== C3. updateArticle also validates? ===" -ForegroundColor Cyan
if($newAid){
  $r = Hit 'PUT' ("/article/" + $newAid) ('{"title":"cat-ok2","content":"y","categoryId":999999}') $tokAdmin
  T 'PUT with invalid category -> 404' (BizCode $r.Body) 404
  $r = Hit 'DELETE' ("/article/" + $newAid) $null $tokAdmin
  T 'cleanup test article' (BizCode $r.Body) 200
}

Write-Host "$nl=== D. does paginated list leak role? ===" -ForegroundColor Cyan
$r = Hit 'GET' '/user/list?pageNum=1&pageSize=5' $null $tokAdmin
Write-Host ("       body: " + $r.Body)

Write-Host ""
Write-Host ("RESULT : {0}/{1} passed" -f $script:ok,$script:n) -ForegroundColor $(if($script:ok -eq $script:n){'Green'}else{'Yellow'})
