#!/home/pi/.rvm/rubies/ruby-1.9.3-p194/bin/ruby
#==============================================================================
#      Program: ztc_tx.rb
#  Description: RPi-->RazBee Simple Serial Transmit Utility 
#       Inputs: $stdin 
#       Author: Steve Dame (sdame172@gmail.com)
#      Version: 0.1 
# Dependencies: http://rubygems.org/gems/serialport
# Prerequisite: gem install serialport
#==============================================================================
require "serialport"

#===================================ZtcMsg=====================================
# ----------------------------------------------------------------------------
#       Class: ZtcMsg
# Description: Sender class for Zigbee ZTC Messages
# ----------------------------------------------------------------------------
class ZtcMsg
  # --------------------------------------------------------------------------
  # constructor
  # --------------------------------------------------------------------------
  def initialize
    #params for serial port running at 38.4Kbaud
    port_str = "/dev/ttyAMA0"
    baud_rate = 38400
    data_bits = 8
    stop_bits = 1
    parity = SerialPort::NONE
    @sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
  end
  
  # --------------------------------------------------------------------------
  # Send a fully formed ZTC byte string command of the form
  #   "02 A3 08 00 AB"  or "02A30800AB"
  # --------------------------------------------------------------------------
  def ztc_send(ztc_full_msg)
    # strip space separators (if any)
    ztc = ztc_full_msg.gsub(' ','')
    puts ztc
    ztc.scan(/../).map do |x| 
       @sp.putc(x.hex) 
       puts x
    end
  end

  # --------------------------------------------------------------------------
  # compute the (lame) XOR checksum "CRC" for a series of ZTC command bytes
  #   note: must exclude the Sync (02) and any existing CRC (last byte) 
  #   Can be of the form: "A3 08 00"  or "A30800"
  # --------------------------------------------------------------------------
  def ztc_crc(msg)
    ztc = msg.gsub(' ','')
    puts ztc
    crc = 0
    ztc.scan(/../).map { |x| crc = crc ^ x.hex }
    puts crc.to_s(16).upcase
    return crc
  end
end
#===================================ZtcMsg=====================================

# Zigbee ZTC CPU Reset Request
=begin
TX: ZTC-CPU_Reset.Request 02 A3 08 00 AB
        Sync    [1 byte]   = 02
        OpGroup [1 byte]   = A3
        OpCode  [1 byte]   = 08
        Length  [1 byte]   = 00
        CRC     [1 byte]   = AB
=end
ztc_rst = "02 A3 08 00 AB"

# Zigbee ZTC Startup Network Request (Coordinator)
=begin
TX: ZTC-StartNwkEx.Request 02 A3 E7 03 C0 08 00 8F
Sync               [1 byte]   = 02
OpGroup            [1 byte]   = A3
OpCode             [1 byte]   = E7
Length             [1 byte]   = 03
DeviceType         [1 byte]   = C0 (Device as ZC)
Startupset         [1 byte]   = 08 (Use ROM set)
Startupcontrolmode [1 byte]   = 00 (Association)
CRC                [1 byte]   = 8F
=end
ztc_start_nwk_zc = "02 A3 E7 03 C0 08 00 8F"

# create a new
z = ZtcMsg.new  

puts "Reset the CPU over ZTC - Hit <CR> when ready to startup network"
z.ztc_send(ztc_rst)

=begin
ztc_rst.scan(/../).map { |x| 
   sp.putc(x.hex) 
   puts x
 }
=end 
 
gets
puts "\nForming and Starting up Zigbee Network as Coordinator"
z.ztc_send(ztc_start_nwk_zc)

=begin
ztc_start_nwk_zc.scan(/../).map { |x|
    sp.putc(x.hex)
    puts x 
    }
=end

# sit in a forever loop and cut and paste ztc sequences
while true do
  printf("\nEnter new ZTC command sequence:");
  s = gets
  z.ztc_send(s)
  sleep(1)
end
sp.close
