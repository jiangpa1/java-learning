$enc=[System.Text.Encoding]::UTF8
$SECRET=[Environment]::GetEnvironmentVariable('JWT_SECRET','User')

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
function Fld { param([string]$b,[string]$n) if($b -match ('"'+$n+'"\s*:\s*(-?\d+)')){ return [int]$Matches[1] } return $null }
function Msg { param([string]$b) if($b -match '"message"\s*:\s*"([^"]*)"'){ return $Matches[1] } return '' }
$script:n=0; $script:ok=0
function T { param($label,$got,$want)
  $script:n++
  if($got -eq $want){ $script:ok++; Write-Host ("  [PASS] {0,-56} {1}" -f $label,$got) -ForegroundColor Green }
  else { Write-Host ("  [FAIL] {0,-56} got={1} want={2}" -f $label,$got,$want) -ForegroundColor Red } }

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
$tok = New-Tok 17 'lisi' 1

Write-Host "" -ForegroundColor Cyan
$r = Hit 'GET' '/user/list' $null $tok
T 'GET /user/list (no params) -> 200' (BizCode $r.Body) 200


$r = Hit 'GET' '/user/list?pageSize=2' $null $tok
T 'GET /user/list?pageSize=2 -> 200' (BizCode $r.Body) 200
T 'pageSize bound = 2' (Fld $r.Body 'pageSize') 2
$cnt = ([regex]::Matches($r.Body,'"id":\d+')).Count
Write-Host "       records  = $cnt"

$r = Hit 'GET' '/user/list?pageNum=1&pageSize=3' $null $tok
T 'GET /user/list?pageNum=1&pageSize=3 -> 200' (BizCode $r.Body) 200

Write-Host "`n" -ForegroundColor Cyan
$r = Hit 'GET' '/user/list?pageSize=999' $null $tok
T 'pageSize=999 -> 400 (Max enforced)' (BizCode $r.Body) 400
Write-Host ("       msg: " + (Msg $r.Body))
$r = Hit 'GET' '/user/list?pageSize=51' $null $tok
T 'pageSize=51 -> 400' (BizCode $r.Body) 400
$r = Hit 'GET' '/user/list?pageSize=50' $null $tok
T 'pageSize=50 -> 200 (boundary ok)' (BizCode $r.Body) 200
$r = Hit 'GET' '/user/list?pageNum=0' $null $tok
T 'pageNum=0 -> 400 (Min enforced)' (BizCode $r.Body) 400
Write-Host ("       msg: " + (Msg $r.Body))

Write-Host "`n" -ForegroundColor Cyan
$r = Hit 'GET' '/article/list' $null $tok
T 'GET /article/list (no params) -> 200' (BizCode $r.Body) 200
$r = Hit 'GET' '/article/list?pageSize=2' $null $tok
T 'GET /article/list?pageSize=2 -> 200' (BizCode $r.Body) 200
$r = Hit 'GET' '/article/list?pageSize=999' $null $tok
T 'GET /article/list?pageSize=999 -> 400' (BizCode $r.Body) 400

Write-Host "`n" -ForegroundColor Cyan
$r = Hit 'GET' '/comment/list?articleId=3' $null $tok
T 'GET /comment/list?articleId=3 -> 200' (BizCode $r.Body) 200
$amp = [char]38
$r = Hit 'GET' ('/comment/list?articleId=3' + $amp + 'pageSize=2') $null $tok
T 'GET /comment/list articleId+pageSize=2 -> 200' (BizCode $r.Body) 200
$r = Hit 'GET' ('/comment/list?articleId=3' + $amp + 'pageSize=999') $null $tok
T 'GET /comment/list pageSize=999 -> 400' (BizCode $r.Body) 400
$r = Hit 'GET' '/comment/list' $null $tok
T 'GET /comment/list without articleId -> 400' (BizCode $r.Body) 400

Write-Host "`n" -ForegroundColor Cyan
$tokUser = New-Tok 18 'zhangsan' 0
$r = Hit 'GET' '/user/list' $null $tokUser
T 'plain user GET /user/list -> 403' (BizCode $r.Body) 403
$r = Hit 'GET' '/user/18' $null $tokUser
T 'plain user reads self -> 200' (BizCode $r.Body) 200
$r = Hit 'GET' '/article/3' $null $tokUser
T 'plain user reads article -> 200' (BizCode $r.Body) 200

Write-Host ""
Write-Host ("RESULT : {0}/{1} passed" -f $script:ok,$script:n) -ForegroundColor $(if($script:ok -eq $script:n){'Green'}else{'Yellow'})
