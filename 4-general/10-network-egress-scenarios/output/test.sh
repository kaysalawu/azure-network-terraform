
function curl_storage_detailed() {
  curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" -H "x-ms-version: 2019-02-02" -H "Authorization: Bearer $2" "$1" -o /dev/null -w "\
HTTP Code: %{http_code}\n\
Time Connect: %{time_connect}s\n\
Time Start Transfer: %{time_starttransfer}s\n\
Total Time: %{time_total}s\n\
Name Lookup Time: %{time_namelookup}s\n\
App Connect Time: %{time_appconnect}s\n\
Redirect Time: %{time_redirect}s\n\
Pre-transfer Time: %{time_pretransfer}s\n\
Size Download: %{size_download} bytes\n\
Size Upload: %{size_upload} bytes\n\
Speed Download: %{speed_download} bytes/s\n\
Speed Upload: %{speed_upload} bytes/s\n\
SSL Verify Result: %{ssl_verify_result}\n\
Num Connects: %{num_connects}\n\
Num Redirects: %{num_redirects}\n\
Server IP: %{remote_ip}\n\
Local IP: %{local_ip}\n"
}


# curl_detailed_info "https://lab10hub481a.blob.core.windows.net/storage/storage.txt" "$storage_access_token"
