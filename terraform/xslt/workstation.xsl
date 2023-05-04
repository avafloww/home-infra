<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0">

  <xsl:output omit-xml-declaration="yes" method="xml" indent="yes" />
  <xsl:strip-space elements="*" />

  <!-- Root level modifications -->
  <xsl:template match="/domain/vcpu" />
  <xsl:template match="/domain/clock" />
  <xsl:template match="/*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />

      <!-- use local time for Windows -->
      <clock offset="localtime">
        <timer name="rtc" tickpolicy="catchup" />
        <timer name="pit" tickpolicy="delay" />
        <timer name="hpet" present="no" />
        <timer name="hypervclock" present="yes" />
      </clock>

      <pm>
        <suspend-to-mem enabled="no" />
        <suspend-to-disk enabled="no" />
      </pm>

      <qemu:commandline>
        <!-- extra args for hotplugger -->
        <qemu:arg value="-chardev" />
        <qemu:arg value="socket,id=mon1,server=on,wait=off,path=/var/lib/libvirt/qemu/workstation-qmp.sock" />
        <qemu:arg value="-mon" />
        <qemu:arg value="chardev=mon1,mode=control,pretty=on" />
      </qemu:commandline>

      <!-- we define this here to centralize CPU config -->
      <vcpu placement="static">16</vcpu>

      <!-- CPU pinning -->
      <cputune>
        <vcpupin vcpu="0" cpuset="14" />
        <vcpupin vcpu="1" cpuset="36" />
        <vcpupin vcpu="2" cpuset="15" />
        <vcpupin vcpu="3" cpuset="37" />
        <vcpupin vcpu="4" cpuset="16" />
        <vcpupin vcpu="5" cpuset="38" />
        <vcpupin vcpu="6" cpuset="17" />
        <vcpupin vcpu="7" cpuset="39" />
        <vcpupin vcpu="8" cpuset="18" />
        <vcpupin vcpu="9" cpuset="40" />
        <vcpupin vcpu="10" cpuset="19" />
        <vcpupin vcpu="11" cpuset="41" />
        <vcpupin vcpu="12" cpuset="20" />
        <vcpupin vcpu="13" cpuset="42" />
        <vcpupin vcpu="14" cpuset="21" />
        <vcpupin vcpu="15" cpuset="43" />
        <emulatorpin cpuset="14,36" />
      </cputune>
    </xsl:copy>
  </xsl:template>

  <!-- assign correct CPU topology -->
  <xsl:template match="/domain/cpu">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />

      <!-- update this if ever changing vcpus value -->
      <topology sockets="1" cores="8" threads="2" />
    </xsl:copy>
  </xsl:template>

  <!-- see: https://github.com/dmacvicar/terraform-provider-libvirt/issues/885 -->
  <xsl:template match="/domain/devices/disk[@device='cdrom']/target/@bus">
    <xsl:attribute name="bus">sata</xsl:attribute>
  </xsl:template>

  <!-- enable secure boot -->
  <xsl:template match="/domain/os/loader/@secure">
    <xsl:attribute name="secure">yes</xsl:attribute>
  </xsl:template>

  <xsl:template match="/domain/features">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />

      <hyperv mode="custom">
        <relaxed state="on" />
        <vapic state="on" />
        <spinlocks state="on" retries="8191" />
        <vpindex state="on" />
        <synic state="on" />
        <reset state="on" />
      </hyperv>

      <!-- required for secure boot -->
      <smm state="on" />
    </xsl:copy>
  </xsl:template>

  <!-- Remove devices -->
  <xsl:template match="/domain/devices/video" />
  <xsl:template match="/domain/devices/audio" />
  <xsl:template match="/domain/devices/graphics" />
  <xsl:template match="/domain/devices/input" />
  <xsl:template match="/domain/devices/controller[@type='usb']" />

  <!-- Add devices -->
  <xsl:template match="/domain/devices">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />

      <!-- emulate TPM 2.0 for Windows 11 -->
      <tpm model="tpm-tis">
        <backend type="emulator" version="2.0" />
      </tpm>

      <!-- be explicit about USB controllers -->
      <controller type="usb" model="nec-xhci" ports="15" /> <!-- usb.0 -->
      <controller type="usb" model="nec-xhci" ports="15" /> <!-- usb1.0 -->

      <!-- bus 0x65 = RTX 3090 in first slot -->
      <!-- bus 0x17 = RTX 3090 in second slot -->
      <hostdev mode="subsystem" type="pci">
        <source>
          <address domain="0x0000" bus="0x65" slot="0x00" function="0x0" />
        </source>
      </hostdev>

      <hostdev mode="subsystem" type="pci">
        <source>
          <address domain="0x0000" bus="0x65" slot="0x00" function="0x1" />
        </source>
      </hostdev>
    </xsl:copy>
  </xsl:template>

  <!-- Copy the rest of the domain definition verbatim -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
