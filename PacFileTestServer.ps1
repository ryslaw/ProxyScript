$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:8080/")
$listener.Start()
Write-Host "The server is working. Set AutoConfigUrl to: http://127.0.0.1:8080/wpad.dat"

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $response = $context.Response
    $response.Headers.Add("Content-Type", "application/x-ns-proxy-autoconfig")
    
    $content = [System.IO.File]::ReadAllBytes("C:\temp\wpad.dat")
    $response.ContentLength64 = $content.Length
    $response.OutputStream.Write($content, 0, $content.Length)
    $response.Close()
    Write-Host "$(Get-Date -Format "HH:mm:ss.ffff")   File wpad.dat has been read"
}