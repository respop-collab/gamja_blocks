@echo off
rem GitHub Actions 워크플로우 설치
rem 원격 도구가 .github 폴더를 쓰지 못해 이 파일로 대신 만든다.
rem 두 번 클릭하면 끝난다.
chcp 65001 >nul
cd /d "%~dp0"
if not exist ".github\workflows" mkdir ".github\workflows"
copy /Y "_workflow_build.yml" ".github\workflows\build.yml" >nul
if exist ".github\workflows\build.yml" (
  echo [OK] .github\workflows\build.yml created
  del /Q "_workflow_build.yml"
) else (
  echo [FAIL] copy failed
)
pause
