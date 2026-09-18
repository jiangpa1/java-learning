$MYSQL='C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
$CNF=Join-Path $env:TEMP 'rg.cnf'
@"
[client]
host=192.168.133.128
port=3306
user=root
password=$env:LEARNING_DB_PASS
"@ | Set-Content $CNF -Encoding ASCII
function RunSql { param([string]$s) $t=Join-Path $env:TEMP 'rg.txt'
  ((($s | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -N -B learning 2>$t)) -join "").Trim() }

function Call { param([string]$Method,[string]$Path,$Obj,[string]$Token)
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=15}
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
function Payload { param([string]$jwt)
  $p=$jwt.Split('.'); if($p.Count -lt 2){ return '(no)' }
  $x=$p[1].Replace('-','+').Replace('_','/'); switch($x.Length % 4){ 2{$x+='=='} 3{$x+='='} }
  try{ [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($x)) }catch{ '(fail)' } }
function Login { param([string]$u,[string]$p)
  $b = Call POST '/auth/login' @{username=$u;password=$p}
  return [pscustomobject]@{ code=(Code $b); access=(Fld $b 'accessToken'); refresh=(Fld $b 'refreshToken'); body=$b } }

$ok=0;$ng=0
function T { param($cond,$desc,$detail)
  if($cond){ $script:ok++; Write-Host "  [PASS] $desc" -ForegroundColor Green }
  else { $script:ng++; Write-Host "  [FAIL] $desc" -ForegroundColor Red; if($detail){ Write-Host "         -> $detail" -ForegroundColor DarkGray } } }
function Info { param($m) Write-Host "         ($m)" -ForegroundColor DarkGray }
function Head { param($m) Write-Host "`n$m" -ForegroundColor White }

$idAdmin = RunSql "SELECT id FROM tb_user WHERE username='lisi';"
$idUser  = RunSql "SELECT id FROM tb_user WHERE username='zhangsan';"
RunSql "UPDATE tb_user SET role=0 WHERE id<>$idAdmin;" | Out-Null
RunSql "UPDATE tb_user SET role=1 WHERE id=$idAdmin;" | Out-Null
$A = Login 'lisi' '123456'
$U = Login 'zhangsan' '123456'
Info "lisi(admin)=$idAdmin zhangsan(user)=$idUser adminCount=$(RunSql "SELECT COUNT(*) FROM tb_user WHERE role=1 AND deleted=0;")"

Write-Host "`n===== PUT /user/role : round 3 (http + mysql only) =====" -ForegroundColor Cyan

Head "[1] validation enforced (@Valid fix)"
$r = Call PUT '/user/role' @{id=$idUser;role=9} $A.access
T ((Code $r) -eq 400) "role=9 -> 400" "got $(Code $r) body=$r"
T ((RunSql "SELECT role FROM tb_user WHERE id=$idUser;") -eq '0') "DB unchanged" "role=$(RunSql "SELECT role FROM tb_user WHERE id=$idUser;")"

$r = Call PUT '/user/role' @{id=$idUser;role=-1} $A.access
T ((Code $r) -eq 400) "role=-1 -> 400" "got $(Code $r) body=$r"

$r = Call PUT '/user/role' @{id=$idUser} $A.access
T ((Code $r) -eq 400) "missing role -> 400" "got $(Code $r) body=$r"
T ((RunSql "SELECT role IS NULL FROM tb_user WHERE id=$idUser;") -eq '0') "role not NULL in DB" ""

$r = Call PUT '/user/role' @{role=1} $A.access
T ((Code $r) -eq 400) "missing id -> 400" "got $(Code $r) body=$r"

$r = Call PUT '/user/role' @{id=999999;role=1} $A.access
T ((Code $r) -eq 404) "non-existent id -> 404" "got $(Code $r) body=$r"

Head "[2] KEY: demoting a NORMAL user invalidates his refresh token"
$U = Login 'zhangsan' '123456'
$r = Call PUT '/user/role' @{id=$idUser;role=0} $A.access
T ((Code $r) -eq 200) "demote normal user -> 200" "got $(Code $r) body=$r"
$r = Call POST '/auth/refresh' @{refreshToken=$U.refresh}
T ((Code $r) -eq 401) "old refreshToken -> 401 (round 2 was 200)" "got $(Code $r) body=$r"

Head "[3] promote invalidates refresh too (consistency)"
$U = Login 'zhangsan' '123456'
$r = Call PUT '/user/role' @{id=$idUser;role=1} $A.access
T ((Code $r) -eq 200) "promote -> 200" "got $(Code $r) body=$r"
$r = Call POST '/auth/refresh' @{refreshToken=$U.refresh}
T ((Code $r) -eq 401) "old refreshToken -> 401 after promotion" "got $(Code $r) body=$r"
T ((RunSql "SELECT role FROM tb_user WHERE id=$idUser;") -eq '1') "zhangsan is admin in DB" ""

Head "[4] last-admin guard (zhangsan is now a 2nd admin)"
$r = Call PUT '/user/role' @{id=$idUser;role=0} $A.access
T ((Code $r) -eq 200) "demote 2nd admin (allowed) -> 200" "got $(Code $r) body=$r"
$r = Call PUT '/user/role' @{id=$idAdmin;role=0} $A.access
T ((Code $r) -eq 403) "self-demote last admin -> 403" "got $(Code $r) body=$r"
T ((RunSql "SELECT role FROM tb_user WHERE id=$idAdmin;") -eq '1') "lisi still admin" ""

Head "[5] role claim reflects DB after re-login"
$U = Login 'zhangsan' '123456'
$pl = Payload $U.refresh
Info "fresh zhangsan payload = $pl"
T ($pl -match '"role"\s*:\s*0') "role claim is 0 (was -1 when polluted)" $pl

Head "[6] plain user cannot change roles"
$r = Call PUT '/user/role' @{id=$idUser;role=1} $U.access
T ((Code $r) -eq 403) "plain user self-promotes -> 403" "got $(Code $r) body=$r"

Head "[7] promoted user can actually use admin powers (end-to-end)"
$r = Call PUT '/user/role' @{id=$idUser;role=1} $A.access
T ((Code $r) -eq 200) "promote -> 200" "got $(Code $r)"
$U2 = Login 'zhangsan' '123456'
Info "his new payload = $(Payload $U2.access)"
$r = Call GET '/user/list' $null $U2.access
T ((Code $r) -eq 200) "newly promoted admin can GET /user/list -> 200" "got $(Code $r) body=$r"
T ((Payload $U2.access) -match '"role"\s*:\s*1') "his token now carries role:1" (Payload $U2.access)

Head "[8] hygiene"
$bad = RunSql "SELECT COUNT(*) FROM tb_user WHERE role NOT IN (0,1) OR role IS NULL;"
T ($bad -eq '0') "no illegal/NULL role rows" "count=$bad"

Head "[cleanup]"
RunSql "UPDATE tb_user SET role=0;" | Out-Null
RunSql "UPDATE tb_user SET role=1 WHERE id=$idAdmin;" | Out-Null
RunSql "SELECT id,username,role,deleted FROM tb_user ORDER BY id;" | ForEach-Object { Write-Host "  $_" }
Write-Host ""
Write-Host ("RESULT : PASS={0}  FAIL={1}" -f $ok,$ng) -ForegroundColor $(if($ng -eq 0){'Green'}else{'Yellow'})
