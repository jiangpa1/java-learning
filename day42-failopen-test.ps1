$enc=[System.Text.Encoding]::UTF8
$SECRET=[Environment]::GetEnvironmentVariable('JWT_SECRET','User')

function Hit { param([string]$Method,[string]$Path,[string]$Json,[string]$Tok)
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=30}
  if($Tok){ $p.Headers=@{Authorization="Bearer $Tok"} }
  if($Json){ $p.ContentType='application/json; charset=utf-8'; $p.Body=$enc.GetBytes($Json) }
  $body=''; $code=-1; $lim=$null; $rem=$null; $ra=$null; $sw=$null
  $t0=Get-Date
  try { $r=Invoke-WebRequest @p
        $code=$r.StatusCode
        $body=[System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
        $lim=$r.Headers['X-RateLimit-Limit']; $rem=$r.Headers['X-RateLimit-Remaining']
        $ra=$r.Headers['Retry-After']
  } catch { $resp=$_.Exception.Response
        if($resp){ $code=[int]$resp.StatusCode
          $sr=New-Object System.IO.StreamReader($resp.GetResponseStream(),[System.Text.Encoding]::UTF8); $body=$sr.ReadToEnd() }
        else { $body=$_.Exception.Message } }
  $sw=[int]((Get-Date)-$t0).TotalMilliseconds
  New-Object psobject -Property @{ Http=$code; Body=$body; Limit=$lim; Rem=$rem; RetryAfter=$ra; Ms=$sw } }
function BizCode { param([string]$b) if($b -match '"code"\s*:\s*(-?\d+)'){ return [int]$Matches[1] } return $null }
function Msg { param([string]$b) if($b -match '"message"\s*:\s*"([^"]*)"'){ return $Matches[1] } return '' }
function Show { param($label,$r)
  Write-Host ("  {0,-40} bizCode={1,-5} limit={2,-5} rem={3,-5} retryAfter={4,-5} {5}ms" -f $label,(BizCode $r.Body),$r.Limit,$r.Rem,$r.RetryAfter,$r.Ms)
  $m = Msg $r.Body
  if($m){ Write-Host "       msg: $m" -ForegroundColor DarkGray } }

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

Write-Host "=== FAIL-OPEN TEST (spring.redis.port = 9999, unreachable) ===" -ForegroundColor Cyan
Write-Host "expected design: rate limit fail-OPEN (allow), blacklist fail-CLOSED (503)" -ForegroundColor DarkGray

Write-Host "`n[1] anonymous + @RateLimit  -> limiter must fail-open" -ForegroundColor White
Show 'POST /auth/login' (Hit 'POST' '/auth/login' '{"username":"lisi","password":"123456"}' '')

Write-Host "`n[2] anonymous + @RateLimit, repeated x6 (limit is 5/min)" -ForegroundColor White
for($i=1;$i -le 6;$i++){
  $r = Hit 'POST' '/auth/register' ('{"username":"foa' + $i + '","password":"123456"}')
  Show ("  register #$i") $r
}

Write-Host "`n[3] authenticated + @RateLimit -> JWT interceptor checks blacklist first" -ForegroundColor White
Show 'GET /article/3 (with valid token)' (Hit 'GET' '/article/3' '' $tok)
Show 'GET /article/list (with token)'    (Hit 'GET' '/article/list?pageNum=1&pageSize=5' '' $tok)

Write-Host "`n[4] authenticated + NO @RateLimit -> isolates the blacklist path" -ForegroundColor White
Show 'POST /auth/logout (with token)'    (Hit 'POST' '/auth/logout' '' $tok)

Write-Host "`n[5] @RateLimit endpoint WITHOUT token and without blacklist check" -ForegroundColor White
Show 'GET /article/3 (no token)'         (Hit 'GET' '/article/3' '')
