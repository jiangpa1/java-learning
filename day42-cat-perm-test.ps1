$MYSQL='C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
$CNF=Join-Path $env:TEMP 'rc.cnf'
@"
[client]
host=192.168.133.128
port=3306
user=root
password=$env:LEARNING_DB_PASS
"@ | Set-Content $CNF -Encoding ASCII
function RunSql { param([string]$s) $t=Join-Path $env:TEMP 'rc.txt'
  ((($s | & $MYSQL "--defaults-extra-file=$CNF" --default-character-set=utf8mb4 -N -B learning 2>$t)) -join "").Trim() }
function Call { param([string]$Method,[string]$Path,$Obj,[string]$Token)
  $p=@{Uri=('http://127.0.0.1:8080'+$Path);Method=$Method;UseBasicParsing=$true;TimeoutSec=20}
  if($Token){ $p.Headers=@{Authorization="Bearer $Token"} }
  if($Obj){ $p.ContentType='application/json; charset=utf-8'; $p.Body=[System.Text.Encoding]::UTF8.GetBytes(($Obj|ConvertTo-Json -Compress)) }
  try{ $r=Invoke-WebRequest @p; return [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) }
  catch{ $resp=$_.Exception.Response
    if($resp){ $sr=New-Object System.IO.StreamReader($resp.GetResponseStream(),[System.Text.Encoding]::UTF8); return $sr.ReadToEnd() }
    return "ERR: $($_.Exception.Message)" } }
function Code { param($b) if($b -match '"code":\s*(-?\d+)'){ [int]$Matches[1] } else { $null } }
function Fld  { param($b,$n) if($b -match ('"'+$n+'"\s*:\s*"([^"]+)"')){ $Matches[1] } else { $null } }
function T { param($cond,$desc,$detail)
  if($cond){ Write-Host "  [PASS] $desc" -ForegroundColor Green }
  else { Write-Host "  [FAIL] $desc" -ForegroundColor Red; if($detail){ Write-Host "         -> $detail" -ForegroundColor DarkGray } } }

$r = Call POST '/auth/login' @{username='lisi';password='123456'};    $tAdmin = Fld $r 'accessToken'
$r = Call POST '/auth/login' @{username='zhangsan';password='123456'}; $tUser  = Fld $r 'accessToken'
$idUser = RunSql "SELECT id FROM tb_user WHERE username='zhangsan';"

Write-Host "===== category write endpoints: admin-only? =====" -ForegroundColor Cyan
$catNew = 'cat_perm_probe'
RunSql "DELETE FROM tb_category WHERE name='$catNew';" | Out-Null

Write-Host "`n[USER] normal user must be blocked on all 3 writes"
$r = Call POST '/category' @{name=$catNew} $tUser
T ((Code $r) -eq 403) "USER POST /category -> 403" "got $(Code $r) body=$r"
$r = Call PUT '/category/1' @{name='x'} $tUser
T ((Code $r) -eq 403) "USER PUT /category/{id} -> 403" "got $(Code $r) body=$r"
$r = Call DELETE '/category/2' $null $tUser
T ((Code $r) -eq 403) "USER DELETE /category/{id} -> 403" "got $(Code $r) body=$r"
$still = RunSql "SELECT COUNT(*) FROM tb_category WHERE id=2 AND deleted=0;"
T ($still -eq '1') "category 2 untouched in DB" "count=$still"

Write-Host "`n[ADMIN] admin must be allowed"
$r = Call POST '/category' @{name=$catNew} $tAdmin
T ((Code $r) -eq 200) "ADMIN POST /category -> 200" "got $(Code $r) body=$r"
$newId = RunSql "SELECT id FROM tb_category WHERE name='$catNew' ORDER BY id DESC LIMIT 1;"
$r = Call PUT "/category/$newId" @{name='cat_perm_probe2'} $tAdmin
T ((Code $r) -eq 200) "ADMIN PUT /category/{id} -> 200" "got $(Code $r) body=$r"
$r = Call DELETE "/category/$newId" $null $tAdmin
T ((Code $r) -eq 200) "ADMIN DELETE /category/{id} -> 200" "got $(Code $r) body=$r"

Write-Host "`n[READ] GET /category/list must stay open to normal users"
$r = Call GET '/category/list' $null $tUser
T ((Code $r) -eq 200) "USER GET /category/list -> 200" "got $(Code $r)"

Write-Host "`n[cleanup]"
RunSql "DELETE FROM tb_category WHERE name IN ('cat_perm_probe','cat_perm_probe2');" | Out-Null
RunSql "SELECT id,name,deleted FROM tb_category ORDER BY id;" | ForEach-Object { Write-Host "  $_" }
