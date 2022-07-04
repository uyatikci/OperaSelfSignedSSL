set /p pass=
set walletDir=D:\MICROS\wallets
set securityDir=D:\MICROS\opera\security
set cacertsFile=D:\ORA\JDK\jre\lib\security\cacerts

IF EXIST D:\ORA\12214ohs\wlserver\server\lib\DemoTrust.jks (
   SET demoTrust=D:\ORA\12214ohs\wlserver\server\lib\DemoTrust.jks
) ELSE (
   IF EXIST D:\ORA\12213ohs\wlserver\server\lib\DemoTrust.jks (
      SET demoTrust=D:\ORA\12213ohs\wlserver\server\lib\DemoTrust.jks
   ) ELSE (
      SET demoTrust=
   )
)

SET keyToolexe=D:\ora\JDK\jre\bin\keytool.exe
IF EXIST D:\ORA\MWFR\12cappr2\oracle_common\bin\orapki.bat (
   SET oraPKIbat=D:\ORA\MWFR\12cappr2\oracle_common\bin\orapki.bat
) ELSE (
   IF EXIST D:\ora\mwfr\oracle_common\bin\orapki.bat (
      SET oraPKIbat=D:\ora\mwfr\oracle_common\bin\orapki.bat
   )
)

IF DEFINED USERDNSDOMAIN (set FQDN=%COMPUTERNAME%.%USERDNSDOMAIN%) ELSE (set FQDN=%COMPUTERNAME%)

SET rndnum=%random%
ROBOCOPY %walletDir% %walletDir%-%rndnum%
IF %ERRORLEVEL% GTR 0 (ERASE %walletDir%\*.* /Q /F)
ROBOCOPY %securityDir% %securityDir%-%rndnum%
IF %ERRORLEVEL% GTR 0 (ERASE %securityDir%\*.* /Q /F)
REN %cacertsFile% cacerts-%rndnum%
IF DEFINED demoTrust (COPY %demoTrust% %demoTrust%-%rndnum% /Y)

%keyToolexe% -genkey -keyalg RSA -dname "CN=%FQDN%, O=Protel, C=TR, ST=IST, L=Istanbul" -alias V5MACHINE -keypass %pass% -keystore %securityDir%\V5MACHINE.jks -storepass %pass% -validity 1461 -keysize 2048
%keyToolexe% -export -alias V5MACHINE -file %securityDir%\%COMPUTERNAME%.cer -keystore %securityDir%\V5MACHINE.jks -storepass %pass%

COPY cacerts-orig %cacertsFile% /Y
%keyToolexe% -storepasswd -new %pass% -keystore %cacertsFile% -storepass changeit
%keyToolexe% -delete -keystore %cacertsFile% -alias ttelesecglobalrootclass2ca -storepass %pass% -noprompt
%keyToolexe% -delete -keystore %cacertsFile% -alias ttelesecglobalrootclass3ca -storepass %pass% -noprompt

%keyToolexe% -importcert -file %securityDir%\%COMPUTERNAME%.cer -alias V5MACHINE -keystore %cacertsFile% -storepass %pass% -storetype JKS -noprompt
%keyToolexe% -importcert -file %securityDir%\%COMPUTERNAME%.cer -alias V5MACHINE -keystore %securityDir%\V5MACHINE.jks -storepass %pass% -storetype JKS -noprompt

IF DEFINED demoTrust (
   %keyToolexe% -delete -keystore %demoTrust% -storepass "DemoTrustKeyStorePassPhrase" -alias V5MACHINE -noprompt
   %keyToolexe% -importcert -file %securityDir%\%COMPUTERNAME%.cer -alias V5MACHINE -keystore %demoTrust% -storepass "DemoTrustKeyStorePassPhrase" -storetype JKS -noprompt
)

call %oraPKIbat% wallet create -wallet %walletDir% -pwd %pass% -auto_login
call %oraPKIbat% wallet jks_to_pkcs12 -wallet %walletDir% -pwd %pass% -keystore %securityDir%\V5MACHINE.jks -jkspwd %pass%
echo 'Y'|CACLS %walletDir%\cwallet.sso /E /T /C /G "Everyone":F


pause
