%% Modulating and Generating the signal in the PicoScope


%% Data Loading
window_freq = 10;
signal_freq = 173e3;
bits = [readmatrix('data.csv')]; %64
% bits = [bits, bits, bits, bits]; %256
% bits = [bits, bits, bits, bits]; %1024

% bits = randi([0,1], [1, 64]);
%bits = [0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 ];

%% Clear command window and close any figures

clc;
close all;

%% Load configuration information

PS2000aConfig;

%% Device connection

% Check if an Instrument session using the device object |ps2000aDeviceObj|
% is still open, and if so, disconnect if the User chooses 'Yes' when prompted.
if (exist('ps2000aDeviceObj', 'var') && ps2000aDeviceObj.isvalid && strcmp(ps2000aDeviceObj.status, 'open'))
    
    openDevice = questionDialog(['Device object ps2000aDeviceObj has an open connection. ' ...
        'Do you wish to close the connection and continue?'], ...
        'Device Object Connection Open');
    
    if (openDevice == PicoConstants.TRUE)
        
        % Close connection to device.
        disconnect(ps2000aDeviceObj);
        delete(ps2000aDeviceObj);
        
    else

        % Exit script if User selects 'No'.
        return;
        
    end
    
end

% Create a device object. 
% The serial number can be specified as a second input parameter.
ps2000aDeviceObj = icdevice('picotech_ps2000a_generic.mdd');

% Connect device object to hardware.
connect(ps2000aDeviceObj);

%% Obtain Signalgenerator group object
% Signal Generator properties and functions are located in the Instrument
% Driver's Signalgenerator group.

sigGenGroupObj = get(ps2000aDeviceObj, 'Signalgenerator');
sigGenGroupObj = sigGenGroupObj(1);

%% Arbitrary waveform generator - set parameters
set(ps2000aDeviceObj.Signalgenerator(1), 'startFrequency', window_freq);
set(ps2000aDeviceObj.Signalgenerator(1), 'stopFrequency', window_freq);
set(ps2000aDeviceObj.Signalgenerator(1), 'offsetVoltage', 0.0);
set(ps2000aDeviceObj.Signalgenerator(1), 'peakToPeakVoltage', 2000.0);

%% Getting the PicoScope AWG buffer size, usually 2^15
awgBufferSize = get(sigGenGroupObj, 'awgBufferSize');

%% Modulation
time_for_window = 1/window_freq;
t = linspace(0, time_for_window, awgBufferSize);
figure(1)
% imshow(reshape(bits, 32, 32) .', 'InitialMagnification',200);

bits = 0.9 * bits;
bits(1) = 1;
% 
% pulses = rectpulse(bits, length(t)/length(bits));
% start_pulse = repelem([1,0],[length(t)/length(bits) length(t)-length(t)/length(bits)]);
% signal_before_modulate = 0.90 * pulses + start_pulse;
y = sin(2*pi * signal_freq * t) .* rectpulse(bits, length(t)/length(bits));
figure(2)
plot(t,y);
disp(bits);

%% Arbitrary waveform generator - Invoking the signal
[status.setSigGenArbitrarySimple] = invoke(sigGenGroupObj, 'setSigGenArbitrarySimple', y);

%% Turn off signal generator
[status.setSigGenOff] = invoke(sigGenGroupObj, 'setSigGenOff');

%% Disconnect device
disconnect(ps2000aDeviceObj);
delete(ps2000aDeviceObj);
