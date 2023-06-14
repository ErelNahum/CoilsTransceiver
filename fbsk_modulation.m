% Binary Frequency Shift Keying (BFSK) Modulation

% Parameters
Fs = 1000;  % Sampling frequency (Hz)
Tb = 1;    % Bit duration (seconds)
f0 = 10;   % Frequency for binary 0 (Hz)
f1 = 20;   % Frequency for binary 1 (Hz)
bits = [1 0 1 1 0 0 1 0 0 1];  % Bits to be transmitted

% Time vector
t = 0:1/Fs:Tb-1/Fs;

% Modulation
modulated_signal = [];
for i = 1:2:length(bits)
    bit1 = bits(i);
    bit2 = bits(i+1);
    
    if bit1 == 0 && bit2 == 0
        modulated_signal = [modulated_signal 0*t];
    elseif bit1 == 0 && bit2 == 1
        modulated_signal = [modulated_signal sin(2*pi*f1*t)];
    elseif bit1 == 1 && bit2 == 0
        modulated_signal = [modulated_signal sin(2*pi*f0*t)];
    elseif bit1 == 1 && bit2 == 1
        modulated_signal = [modulated_signal 0.5*(sin(2*pi*f1*t) + sin(2*pi*f0*t))];
    end
end

% Plotting
t_total = 0:1/Fs:Tb*length(bits)/2-1/Fs;
figure;
subplot(2, 1, 1);
plot(t_total, modulated_signal);
xlabel('Time (s)');
ylabel('Amplitude');
title('BFSK Modulated Signal');