function [y] = bfsk_modulate(t, f0, f1, bits)
%BFSK_MODULATE Summary of this function goes here
%   Detailed explanation goes here
bit1 = bits(1:2:end);
bit2 = bits(2:2:end);

for i = 1:length(bit1)
    if bit1(i) > 0 && bit2(i) > 0
        bit1(i) = bit1(i) / 2;
        bit2(i) = bit2(i) / 2;
    end
end

    
modulated_signal = sin(2 * pi * f0 * t) .* rectpulse(bit1, length(t)/length(bit1)) + sin(2*pi*f1*t) .* rectpulse(bit2, length(t)/length(bit2));

y = modulated_signal;
end

