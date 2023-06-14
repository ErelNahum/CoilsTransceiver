function [freq_vec,shifted_fft_vec]=calc_fft(signal,fs)
    % calculate the physical (‘real’) frequencies vector:
    N=length(signal);	% number of time-domain samples
    dt=1/fs;		% time between samples = (sampling frequency)^-1
    df=1/(N*dt);      % the frequency resolution (df=1/max_T)
    
    %% generate proper physical frequency vector (after fftshift)
    if mod(N,2)==0
        freq_vec= df*((1:N)-1-N/2);     % frequency vector for EVEN length vectors: f =[-f_max,-f_max+df,...,0,...,f_max-df]
    else
        freq_vec= df*((1:N)-0.5-N/2);   % frequency vector for ODD length vectors f =[-f_max,-f_max+fw,...,0,...,f_max]
    end
    
    shifted_fft_vec=fftshift(fft(signal)); % Fourier-transform the signal
end
% %% plot Fourier amplitude and phase with real physical frequencies
% figure;
% subplot(2,1,1);
% plot(freq_vec,abs(shifted_fft_vec)/N,col);
% xlabel('frequency (Hz)');
% ylabel('FFT amplitude')
% title('normalized FFT amplitude')
% grid on
% subplot(2,1,2);
% plot(freq_vec,(angle(shifted_fft_vec))/pi,col);
% xlabel('frequency (Hz)');
% ylabel('phase (Rad/Pi)')
% grid on
