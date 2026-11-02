Name:           dell-7320-camera-kmods
Version:        0.1
Release:        3%{?dist}
Summary:        Experimental front camera kernel modules for Dell Latitude 7320 Detachable
License:        GPL-2.0-only
BuildArch:      x86_64
%{!?kver:%global kver UNSET}
Requires:       kernel-uname-r = %{kver}

%description
Locally patched TPS68470, OV5675 and IPU bridge modules for the Dell Latitude
7320 Detachable. This package is experimental and built for one exact kernel.


Source0: intel_skl_int3472_tps68470.ko
Source1: ov5675.ko
Source2: ipu-bridge.ko
Source3: dell-7320-camera.conf

%prep

%build

%install
install -D -m 0644 %{_sourcedir}/intel_skl_int3472_tps68470.ko %{buildroot}/usr/lib/modules/%{kver}/kernel/drivers/platform/x86/intel/int3472/intel_skl_int3472_tps68470.ko
install -D -m 0644 %{_sourcedir}/ov5675.ko %{buildroot}/usr/lib/modules/%{kver}/kernel/drivers/media/i2c/ov5675.ko
install -D -m 0644 %{_sourcedir}/ipu-bridge.ko %{buildroot}/usr/lib/modules/%{kver}/kernel/drivers/media/pci/intel/ipu-bridge.ko
install -D -m 0644 %{_sourcedir}/dell-7320-camera.conf %{buildroot}/usr/lib/modules-load.d/dell-7320-camera.conf
xz -f -T0 --check=crc32 %{buildroot}/usr/lib/modules/%{kver}/kernel/drivers/platform/x86/intel/int3472/intel_skl_int3472_tps68470.ko
xz -f -T0 --check=crc32 %{buildroot}/usr/lib/modules/%{kver}/kernel/drivers/media/i2c/ov5675.ko
xz -f -T0 --check=crc32 %{buildroot}/usr/lib/modules/%{kver}/kernel/drivers/media/pci/intel/ipu-bridge.ko

%post
/usr/sbin/depmod -a %{kver} || :

%postun
/usr/sbin/depmod -a %{kver} || :

%files
/usr/lib/modules/%{kver}/kernel/drivers/platform/x86/intel/int3472/intel_skl_int3472_tps68470.ko.xz
/usr/lib/modules/%{kver}/kernel/drivers/media/i2c/ov5675.ko.xz
/usr/lib/modules/%{kver}/kernel/drivers/media/pci/intel/ipu-bridge.ko.xz
/usr/lib/modules-load.d/dell-7320-camera.conf
