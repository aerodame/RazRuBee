#!/home/pi/.rvm/rubies/ruby-1.9.3-p194/bin/ruby
require "serialport"
require "statemachine"

#===================================ZtcMsg=====================================
# ----------------------------------------------------------------------------
class ZtcRxMachineContext
  attr_accessor :statemachine

  def initialize
    @crc = 0
  end

  def rx_sync
  end

  def rx_valid_op_group
    if  1
    else
    end
  end

  def prompt_money
    puts "$.#{@amount_tendered}: more money please"
  end

  def prompt_selection
    puts "please make a selection"
  end
end


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

    # set up the ZTC message state machine
    @ztcMsgSM = Statemachine.build do
      #     CURRENT STATE     EVENT                 NEXT STATE          ACTION (Optional)
      #     ----------------- --------------------- ------------------- -----------------
      trans :wait_for_sync,   :rx_sync,             :op_group_check
      trans :op_group_check,  :rx_valid_op_group,   :op_code_check
      trans :op_group_check,  :rx_invalid_op_group, :wait_for_sync
      trans :op_code_check,   :rx_valid_op_code,    :get_length
      trans :get_length,      :rx_length_gt_zero,   :build_payload
      trans :get_length,      :rx_length_zero,      :check_crc        
      trans :build_payload,   :rx_payload_byte,     :build_payload
      trans :build_payload,   :rx_final_byte,       :check_crc
      trans :check_crc,       :rx_crc,              :wait_for_sync
      
      
      state :wait_for_sync
      
      context ZtcRxMachineContext.new
       
    end
    @ztcMsgSM.context.statemachine = @ztcMsgSM
  end
  
=begin  
  Sync               [1 byte]   = 02
  OpGroup            [1 byte]   = A3
  OpCode             [1 byte]   = E7
  Length             [1 byte]   = 03
  
  DeviceType         [1 byte]   = C0 (Device as ZC)
  Startupset         [1 byte]   = 08 (Use ROM set)
  Startupcontrolmode [1 byte]   = 00 (Association)

  CRC                [1 byte]   = 8F  
=end  

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
  def ztc_rx_statemachine
  end
  # --------------------------------------------------------------------------


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

#params for serial port
port_str = "/dev/ttyAMA0"
baud_rate = 38400 
data_bits = 8
stop_bits = 1
parity = SerialPort::NONE
 
sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
 
#just read forever
printf("Read ZTC Port at %d baud\n",baud_rate);
while true do
  c = sp.getbyte
  s = sprintf("%02x", c).upcase
  puts s
end

sp.close


=begin
while buffer = io.read
  str << buffer.unpack('H*')
end



        
        
=end
