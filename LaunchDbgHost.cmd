@echo off

setlocal
pushd %~dp0

path %path%;.\App\qemu;.\App\idw

qemu-system-i386 -cpu 486 -m 64 -net nic,model=pcnet -serial tcp::4444,server,nowait -hda Image\DbgHost.vhd -hdb fat:rw:%~dp0App\WinDbg

popd
endlocal