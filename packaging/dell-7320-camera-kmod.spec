%global buildforkernels akmod
%global debug_package %{nil}

Name:           dell-7320-camera-kmod
Version:        0.2
Release:        1%{?dist}
Summary:        Dell Latitude 7320 Detachable camera kernel modules
License:        GPL-2.0-only
URL:            https://github.com/githomeserver/latitude-7320-camera
ExclusiveArch:  x86_64
Provides:       %{name}-common = %{version}-%{release}

Source0:        %{name}-%{version}.tar.xz
Source1:        dell-7320-camera-kmod-excludekernel-filterfile
Source2:        dell-7320-camera.conf
BuildRequires:  %{_bindir}/kmodtool
BuildRequires:  elfutils-libelf-devel
BuildRequires:  gcc
BuildRequires:  make

%{expand:%(kmodtool --target %{_target_cpu} --repo rpmfusion --kmodname %{name} --filterfile %{SOURCE1} %{?buildforkernels:--%{buildforkernels}} %{?kernels:--for-kernels "%{?kernels}"} 2>/dev/null)}

%description
Patched TPS68470, OV5675 and IPU bridge kernel modules for the Dell Latitude
7320 Detachable. The akmod builds kernel-specific binaries from the included
source against each installed kernel's matching kernel-devel package.

%prep
%{?kmodtool_check}
kmodtool --target %{_target_cpu} --repo rpmfusion --kmodname %{name} --filterfile %{SOURCE1} %{?buildforkernels:--%{buildforkernels}} %{?kernels:--for-kernels "%{?kernels}"}
%setup -q -n %{name}-%{version}

%build
for kernel_version in %{?kernel_versions}; do
    kver=${kernel_version%%___*}
    ksrc=${kernel_version##*___}
    build_dir="_kmod_build_${kver}"
    mkdir -p "$build_dir"
    cp -a drivers "$build_dir/"
    for module_dir in \
        drivers/platform/x86/intel/int3472 \
        drivers/media/i2c \
        drivers/media/pci/intel; do
        make -C "$ksrc" M="$PWD/$build_dir/$module_dir" modules
    done
done

%install
for kernel_version in %{?kernel_versions}; do
    kver=${kernel_version%%___*}
    dest=%{buildroot}/%{kmodinstdir_prefix}/$kver/%{kmodinstdir_postfix}
    install -d "$dest"
    install -m 0644 \
        "_kmod_build_${kver}/drivers/platform/x86/intel/int3472/intel_skl_int3472_tps68470.ko" \
        "_kmod_build_${kver}/drivers/media/i2c/ov5675.ko" \
        "_kmod_build_${kver}/drivers/media/pci/intel/ipu-bridge.ko" \
        "$dest/"
done
install -D -m 0644 %{SOURCE2} %{buildroot}%{_prefix}/lib/modules-load.d/dell-7320-camera.conf
%{?akmod_install}

%files
%{_prefix}/lib/modules-load.d/dell-7320-camera.conf

%changelog
* Tue Nov 03 2026 Codex <noreply@example.invalid> - 0.2-1
- Build kernel modules through akmods for installed kernels
