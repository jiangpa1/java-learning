$MYSQL='C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
$CNF=Join-Path $env:TEMP 'rt2.cnf'
@"
[client]
host=192.168.133.128
port=3306
user=root
password=$env:LEARNING_DB_PASS
"@ | Set-Content $CNF -Encoding ASCII

$script:ok = 0
$script:ng = 0

function RunSql { param([string]$s)
  $t=Join-Path $env:TEMP 'rt2.txt'
  $o = $s | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -N -B learning 2>$t
  return (($o -join "") -replace "`r|`n","").Trim()
}
function Call { param([string]$Method,[string]$Path,$Obj,[string]$Token)
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=20}
  if($Token){ $p.Headers=@{Authorization="Bearer $Token"} }
  if($Obj){ $p.ContentType='application/json; charset=utf-8'
            $p.Body=[System.Text.Encoding]::UTF8.GetBytes(($Obj|ConvertTo-Json -Compress)) }
  try{ $r=Invoke-WebRequest @p; return [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) }
  catch{ $resp=$_.Exception.Response
    if($resp){ $sr=New-Object System.IO.StreamReader($resp.GetResponseStream(),[System.Text.Encoding]::UTF8); return $sr.ReadToEnd() }
    return "ERR: $($_.Exception.Message)" }
}
function Code { param($b) if($b -match '"code":\s*(-?\d+)'){ [int]$Matches[1] } else { $null } }
function Fld  { param($b,$n) if($b -match ('"'+$n+'"\s*:\s*"([^"]+)"')){ $Matches[1] } else { $null } }
function Payload { param([string]$jwt)
  $parts=$jwt.Split('.')
  if($parts.Count -lt 2){ return '(not a jwt)' }
  $x=$parts[1].Replace('-','+').Replace('_','/'); switch($x.Length % 4){ 2{$x+='=='} 3{$x+='='} }
  try { [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($x)) } catch { '(decode fail)' }
}
function T { param($cond,$desc,$detail)
  if($cond){ $script:ok++; Write-Host "  [PASS] $desc" -ForegroundColor Green }
  else { $script:ng++; Write-Host "  [FAIL] $desc" -ForegroundColor Red; if($detail){ Write-Host "         -> $detail" -ForegroundColor DarkGray } } }
function Info { param($m) Write-Host "         ($m)" -ForegroundColor DarkGray }
function Head { param($m) Write-Host "`n$m" -ForegroundColor White }
function Expect { param($expect,$actual,$desc,$body)
  T ($actual -eq $expect) ("$desc  [expect $expect, got $actual]") "body=$body" }

Write-Host "===== role / ownership acceptance test (round 2) =====" -ForegroundColor Cyan
$idAdmin = RunSql "SELECT id FROM tb_user WHERE username='lisi';"
$idUser  = RunSql "SELECT id FROM tb_user WHERE username='zhangsan';"
Info "lisi(admin) id=$idAdmin   zhangsan(user) id=$idUser"

$r = Call POST '/auth/login' @{username='lisi';password='123456'}
$tAdmin = Fld $r 'accessToken'
$r = Call POST '/auth/login' @{username='zhangsan';password='123456'}
$tUser = Fld $r 'accessToken'
Info "admin token payload = $(Payload $tAdmin)"
Info "user  token payload = $(Payload $tUser)"

Head "[1] token carries role"
T ((Payload $tAdmin) -match '"role"\s*:\s*1') "admin token role:1" ""
T ((Payload $tUser)  -match '"role"\s*:\s*0') "user token role:0" ""

Head "[2] GET /user/{id}  -- 'self OR admin'  (defect 1 was here)"
$r = Call GET "/user/$idUser" $null $tUser
Expect 200 (Code $r) "USER reads SELF" $r
$r = Call GET "/user/$idAdmin" $null $tUser
Expect 403 (Code $r) "USER reads ADMIN" $r
$r = Call GET "/user/$idAdmin" $null $tAdmin
Expect 200 (Code $r) "ADMIN reads SELF" $r
$r = Call GET "/user/$idUser" $null $tAdmin
Expect 200 (Code $r) "ADMIN reads OTHER" $r

Head "[3] GET /user/list  -- admin only"
$r = Call GET '/user/list' $null $tAdmin
Expect 200 (Code $r) "ADMIN -> 200" $r
$r = Call GET '/user/list' $null $tUser
Expect 403 (Code $r) "USER  -> 403" $r
Info "real code of that 403 body: $(Code $r) message check below"
T ($r -notmatch '"code":\s*401') "rejection is NOT 401 any more" $r

Head "[4] DELETE /user/{id}  -- 'self OR admin'  (defect 2 was here)"
RunSql "DELETE FROM tb_user WHERE username IN ('selfdel','victim1');" | Out-Null
$null = Call POST '/auth/register' @{username='selfdel';password='123456'}
$null = Call POST '/auth/register' @{username='victim1';password='123456'}
$idSelf   = RunSql "SELECT id FROM tb_user WHERE username='selfdel';"
$idVictim = RunSql "SELECT id FROM tb_user WHERE username='victim1';"
$r = Call POST '/auth/login' @{username='selfdel';password='123456'}
$tSelf = Fld $r 'accessToken'
$r = Call POST '/auth/login' @{username='victim1';password='123456'}
$tVictim = Fld $r 'accessToken'
Info "selfdel id=$idSelf  victim1 id=$idVictim"

$r = Call DELETE "/user/$idVictim" $null $tSelf
Expect 403 (Code $r) "USER deletes OTHER" $r
$r = Call DELETE "/user/$idAdmin" $null $tUser
Expect 403 (Code $r) "USER deletes ADMIN" $r

$r = Call DELETE "/user/$idVictim" $null $tAdmin
Expect 200 (Code $r) "ADMIN deletes OTHER" $r
$after = RunSql "SELECT deleted FROM tb_user WHERE id=$idVictim;"
T ($after -eq '1') "victim1 row now deleted=1" "deleted=$after"

$r = Call DELETE "/user/$idSelf" $null $tSelf
Expect 200 (Code $r) "USER deletes SELF" $r
$after = RunSql "SELECT deleted FROM tb_user WHERE id=$idSelf;"
T ($after -eq '1') "selfdel row now deleted=1" "deleted=$after"

Head "[5] PUT /user/{id}  -- ownership only (no role bypass)"
$r = Call PUT "/user/$idUser" @{id=$idUser;nickname='x'} $tAdmin
Expect 403 (Code $r) "ADMIN tries to rename OTHER (ownership-only design)" $r
$r = Call PUT "/user/$idUser" @{id=$idUser;nickname='zhangsan'} $tUser
Expect 200 (Code $r) "USER renames SELF" $r

Head "[6] escalation attempts by normal user"
$r = Call PUT "/user/$idUser/role" $null $tUser
Expect 403 (Code $r) "USER promotes SELF" $r
$r = Call PUT "/user/$idAdmin/role" $null $tUser
Expect 403 (Code $r) "USER promotes ADMIN" $r
$role = RunSql "SELECT role FROM tb_user WHERE id=$idUser;"
T ($role -eq '0') "zhangsan role still 0" "role=$role"

Head "[7] 404 vs 403 ordering (existence checked first)"
$r = Call GET '/user/999999' $null $tUser
Expect 404 (Code $r) "USER reads a NON-EXISTENT user -> 404 not 403" $r
$r = Call DELETE '/user/999999' $null $tUser
Expect 404 (Code $r) "USER deletes NON-EXISTENT -> 404 not 403" $r

Head "[8] regression: read endpoints unaffected"
foreach($p in @('/article/list?pageNum=1&pageSize=5','/category/list','/comment/list?articleId=3&pageNum=1&pageSize=3')){
  $r = Call GET $p $null $tUser
  Expect 200 (Code $r) "USER GET $p" $r
}

Head "[9] refresh keeps role"
$r = Call POST '/auth/login' @{username='lisi';password='123456'}
$rt = Fld $r 'refreshToken'
$r = Call POST '/auth/refresh' @{refreshToken=$rt}
Expect 200 (Code $r) "refresh 200" $r
$nt = Fld $r 'accessToken'
T ((Payload $nt) -match '"role"\s*:\s*1') "rotated token still role:1" (Payload $nt)

Head "[10] no token at all"
$r = Call GET '/user/list' $null $null
Expect 401 (Code $r) "no Authorization -> 401 (JWT interceptor)" $r

Head "[cleanup]"
RunSql "DELETE FROM tb_user WHERE username IN ('selfdel','victim1');" | Out-Null
RunSql "UPDATE tb_user SET role=0 WHERE id=$idUser;" | Out-Null
RunSql "SELECT id,username,role,deleted FROM tb_user ORDER BY id;" | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host ("RESULT : PASS={0}  FAIL={1}" -f $script:ok,$script:ng) -ForegroundColor $(if($script:ng -eq 0){'Green'}else{'Yellow'})
