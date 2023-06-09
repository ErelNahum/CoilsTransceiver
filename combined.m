%% Modulating and Generating the signal in the PicoScope


%% Data Loading
window_freq = 10;
signal_freq = 173e3;
bits = [readmatrix('data.csv')]; %64
bits = [bits, bits, bits, bits]; %256
%%
bits = [bits, bits]; %512
%bits = [bits, bits, bits, bits]; %1024
% bits = [bits, bits]; %4096

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
% figure(1)
% imshow(reshape(bits, 32, 32) .', 'InitialMagnification',200);

bits = 0.8 * bits;
bits(1) = 1;
% 
% pulses = rectpulse(bits, length(t)/length(bits));
% start_pulse = repelem([1,0],[length(t)/length(bits) length(t)-length(t)/length(bits)]);
% signal_before_modulate = 0.90 * pulses + start_pulse;
% f0 = 165e3;
% f1 = 175e3;
% [y] = bfsk_modulate(t, f0, f1, bits);
% plot(t, y);
y = sin(2*pi * signal_freq * t) .* rectpulse(bits, length(t)/length(bits));
% figure(2)
% plot(t,y);
% y = 0.5*sin(2*pi*173e3*t);

%% Arbitrary waveform generator - Invoking the signal
[status.setSigGenArbitrarySimple] = invoke(sigGenGroupObj, 'setSigGenArbitrarySimple', y);

%% Verify timebase index and maximum number of samples
% Use the |ps2000aGetTimebase2()| function to query the driver as to the
% suitability of using a particular timebase index and the maximum number
% of samples available in the segment selected, then set the |timebase|
% property if required.
%
% To use the fastest sampling interval possible, enable one analog
% channel and turn off all other channels.
%
% Use a while loop to query the function until the status indicates that a
% valid timebase index has been selected. In this example, the timebase
% index of 64 is valid.

% Initial call to ps2000aGetTimebase2() with parameters:
%
% timebase      : 64
% segment index : 0

status.getTimebase2 = PicoStatus.PICO_INVALID_TIMEBASE;
timebaseIndex = 64;

while (status.getTimebase2 == PicoStatus.PICO_INVALID_TIMEBASE)
    
    [status.getTimebase2, timeIntervalNanoseconds, maxSamples] = invoke(ps2000aDeviceObj, ...
                                                                    'ps2000aGetTimebase2', timebaseIndex, 0);
    
    if (status.getTimebase2 == PicoStatus.PICO_OK)
       
        break;
        
    else
        
        timebaseIndex = timebaseIndex + 1;
        
    end    
    
end

fprintf('Timebase index: %d, sampling interval: %d ns\n', timebaseIndex, timeIntervalNanoseconds);

% Configure the device object's |timebase| property value.
set(ps2000aDeviceObj, 'timebase', timebaseIndex);
%%
[status.setChA] = invoke(ps2000aDeviceObj, 'ps2000aSetChannel', ps2000aEnuminfo.enPS2000AChannel.PS2000A_CHANNEL_A, PicoConstants.TRUE, ps2000aEnuminfo.enPS2000ACoupling.PS2000A_AC, ps2000aEnuminfo.enPS2000ARange.PS2000A_1V, 0.0);

%% Set simple trigger
% Set a trigger on channel A, with an auto timeout - the default value for
% delay is used.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps2000aDeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

% Set the |autoTriggerMs| property in order to automatically trigger the
% oscilloscope after 1 second if a trigger event has not occurred. Set to 0
% to wait indefinitely for a trigger event.

set(triggerGroupObj, 'autoTriggerMs', 1000);

% Channel     : 0 (ps2000aEnuminfo.enPS2000AChannel.PS2000A_CHANNEL_A)
% Threshold   : 1000 mV
% Direction   : 2 (ps2000aEnuminfo.enPS2000AThresholdDirection.PS2000A_RISING)

[status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 595, 3);

%% Set block parameters and capture data
% Capture a block of data and retrieve data values for channels A and B.

% Block data acquisition properties and functions are located in the 
% Instrument Driver's Block group.

blockGroupObj = get(ps2000aDeviceObj, 'Block');
blockGroupObj = blockGroupObj(1);

% Set pre-trigger and post-trigger samples as required - the total of this
% should not exceed the value of |maxSamples| returned from the call to
% |ps2000aGetTimebase2()|. The default of 0 pre-trigger and 8192 post-trigger
% samples is used in this example.

% set(ps2000aDeviceObj, 'numPreTriggerSamples', 0);
set(ps2000aDeviceObj, 'numPostTriggerSamples', round(10^8 / timeIntervalNanoseconds));

%%
% This example uses the |runBlock()| function in order to collect a block of
% data - if other code needs to be executed while waiting for the device to
% indicate that it is ready, use the |ps2000aRunBlock()| function and poll
% the |ps2000aIsReady()| function.

% Capture a block of data:
%
% segment index: 0 (The buffer memory is not segmented in this example)

[status.runBlock] = invoke(blockGroupObj, 'runBlock', 0);

% Retrieve data values:

startIndex              = 0;
segmentIndex            = 0;
downsamplingRatio       = 1;
downsamplingRatioMode   = ps2000aEnuminfo.enPS2000ARatioMode.PS2000A_RATIO_MODE_NONE;

% Provide additional output arguments for other channels e.g. chC for
% channel C if using a 4-channel PicoScope.
[numSamples, overflow, chA] = invoke(blockGroupObj, 'getBlockData', startIndex, segmentIndex, ...
                                            downsamplingRatio, downsamplingRatioMode);

%% Process data
% In this example the data values returned from the device are displayed in
% plots in a Figure.

figure1 = figure('Name','PicoScope 2000 Series (A API) Example - Block Mode Capture', ...
    'NumberTitle','off');

% Calculate sampling interval (nanoseconds) and convert to milliseconds.
% Use the |timeIntervalNanoSeconds| output from the |ps2000aGetTimebase2()|
% function or calculate it using the main Programmer's Guide.
% Take into account the downsampling ratio used.

timeNs = double(timeIntervalNanoseconds) * downsamplingRatio * double(0:numSamples - 1);
timeMs = timeNs / 1e6;

% Channel A
axisHandleChA = subplot(2,1,1); 
plot(axisHandleChA, timeMs, chA, 'b');
ylim(axisHandleChA, [-1000 1000]); % Adjust vertical axis for signal.

title(axisHandleChA, 'Channel A');
xlabel(axisHandleChA, 'Time (ms)');
ylabel(axisHandleChA, 'Voltage (mV)');
grid(axisHandleChA);

% Channel B
axisHandleChB = subplot(2,1,2); 
plot(axisHandleChB, 2*y, 'r');
ylim(axisHandleChB, [-2.5 2.5]); % Adjust vertical axis for signal.
xlim(axisHandleChB, [0, length(y)])

title(axisHandleChB, 'Signal Generated');
xlabel(axisHandleChB, 'Sample');
ylabel(axisHandleChB, 'Voltage (V)');
grid(axisHandleChB);

% figure(3)
% plot(abs(calc_fft(chA, 10^9/timeIntervalNanoseconds)))

%% Turn off signal generator
[status.setSigGenOff] = invoke(sigGenGroupObj, 'setSigGenOff');

%% Stop the device
[status.stop] = invoke(ps2000aDeviceObj, 'ps2000aStop');

%% Disconnect device
disconnect(ps2000aDeviceObj);
delete(ps2000aDeviceObj);
