# 檢查是否已存在 NetNat
if (!(Get-NetNat -Name 'USB_NAT' -ErrorAction SilentlyContinue)) {
    Write-Host "Creating USB_NAT NAT..."
    New-NetNat -Name 'USB_NAT' -InternalIPInterfaceAddressPrefix 192.168.137.0/24
} else {
    Write-Host "NetNat USB_NAT already exists."
}