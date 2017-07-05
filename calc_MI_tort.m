%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to calculate a comodulogram of Modulation Index (MI) values
% from Fieldtrip data using the metric from (Tort et al., 2010)
%
% Inputs:
% - virtsens = MEG data (1 channel)
% - toi = times of interest in seconds e.g. [0.3 1.5]
% - phases of interest e.g. [4 22] currently increasing in 1Hz steps
% - amplitudes of interest e.g. [30 80] currently increasing in 2Hz steps
% - diag = 'yes' or 'no' to turn on or off diagrams during computation
% - surrogates = 'yes' or 'no' to turn on or off surrogates during computation
%
% For details of the PAC method go to: http://jn.physiology.org/content/104/2/1195.short
%
% Written by: Robert Seymour - Aston Brain Centre
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [MI_matrix] = calc_MI_tort(virtsens,toi,phase,amp,diag,surrogates)

if diag == 'no'
    disp('NOT producing any images during the computation of MI')
end

% Determine size of final matrix
phase_length = length(phase(1):1:phase(2));
amp_length = length(amp(1):2:amp(2));

% Create matrix to hold comod
MI_matrix = zeros(amp_length,phase_length);
clear phase_length amp_length

row1 = 1;
row2 = 1;

for k = phase(1):1:phase(2)
    for p = amp(1):2:amp(2)
        %% Bandpass filter individual trials usign a two-way Butterworth Filter
        
        % Specifiy bandwith = +- 1/2.5 of center frequency
        Af1 = round(p -(p/2.5)); Af2 = round(p +(p/2.5));
        
        % Filter data at phase frequency using Butterworth filter
        cfg = [];
        cfg.showcallinfo = 'no';
        cfg.bpfilter = 'yes';
        cfg.bpfreq = [k-1 k+1]; %+-1Hz - could be changed if necessary
        cfg.hilbert = 'angle';
        [virtsens_phase] = ft_preprocessing(cfg, virtsens);
        
        % Filter data at amp frequency using Butterworth filter
        cfg = [];
        cfg.showcallinfo = 'no';
        cfg.bpfilter = 'yes';
        cfg.bpfreq = [Af1 Af2];
        cfg.hilbert = 'abs';
        [virtsens_amp] = ft_preprocessing(cfg, virtsens);
        
        % Cut out window of interest (phase) - should exlude phase-locked
        % responses (e.g. ERPs)
        cfg = [];
        cfg.toilim = toi; %specfied in function calls
        cfg.showcallinfo = 'no';
        post_grating_phase = ft_redefinetrial(cfg,virtsens_phase);
        post_grating_amp = ft_redefinetrial(cfg,virtsens_amp);
        
        % Variable to hold MI for all trials
        MI_comb = [];
        
        % For each trial...
        for trial_num = 1:length(virtsens.trial)
            
            % Extract phase and amp info using hilbert transform
            Phase= post_grating_phase.trial{1, trial_num}; % getting the phase
            Amp= post_grating_amp.trial{1, trial_num}; % getting the amplitude envelope
            
            nbin=18; % % we are breaking 0-360o in 18 bins, ie, each bin has 20o
            position=zeros(1,nbin); % this variable will get the beginning (not the center) of each bin (in rads)
            winsize = 2*pi/nbin;
            for j=1:nbin
                position(j) = -pi+(j-1)*winsize;
            end
            
            % now we compute the mean amplitude in each phase:
            MeanAmp=zeros(1,nbin);
            for j=1:nbin
                I = find(Phase <  position(j)+winsize & Phase >=  position(j));
                MeanAmp(j)=mean(Amp(I));
            end
            
            % so note that the center of each bin (for plotting purposes) is
            % position+winsize/2
            
            % at this point you might want to plot the result to see if there's any
            % amplitude modulation
            if strcmp(diag, 'yes')
                bar(10:20:720,[MeanAmp,MeanAmp]/sum(MeanAmp),'k')
                xlim([0 720])
                set(gca,'xtick',0:360:720)
                xlabel('Phase (Deg)')
                ylabel('Amplitude')
            end
            
            % and next you quantify the amount of amp modulation by means of a
            % normalized entropy index (Tort et al PNAS 2008):
            
            MI=(log(nbin)-(-sum((MeanAmp/sum(MeanAmp)).*log((MeanAmp/sum(MeanAmp))))))/log(nbin);
            
            % Add this value to all other all other values
            MI_comb(trial_num) = MI;
            
        end
        
        if strcmp(surrogates, 'yes')
            
            % Variable to surrogate MI
            MI_surr = [];
            
            % For each surrogate (surrently hard-coded for 200, could be changed)...
            for surr = 1:1000
                % Get 2 random trial numbers
                trial_num = randperm(length(post_grating_phase.trialinfo),2);
                
                % Extract phase and amp info using hilbert transform
                % But for different trials
                Phase= post_grating_phase.trial{1, trial_num(1)}(randperm(length(post_grating_phase.trial{1,trial_num(1)}))); % getting the phase
                Amp = post_grating_amp.trial{1,trial_num(2)};
                
                % Apply Tort et al (2010) approach)
                nbin=18; % % we are breaking 0-360o in 18 bins, ie, each bin has 20o
                position=zeros(1,nbin); % this variable will get the beginning (not the center) of each bin (in rads)
                winsize = 2*pi/nbin;
                for j=1:nbin
                    position(j) = -pi+(j-1)*winsize;
                end
                
                % now we compute the mean amplitude in each phase:
                MeanAmp=zeros(1,nbin);
                for j=1:nbin
                    I = find(Phase <  position(j)+winsize & Phase >=  position(j));
                    MeanAmp(j)=mean(Amp(I));
                end
                
                % so note that the center of each bin (for plotting purposes) is
                % position+winsize/2
                
                % at this point you might want to plot the result to see if there's any
                % amplitude modulation
                if strcmp(diag, 'yes')
                    bar(10:20:720,[MeanAmp,MeanAmp]/sum(MeanAmp),'k')
                    xlim([0 720])
                    set(gca,'xtick',0:360:720)
                    xlabel('Phase (Deg)')
                    ylabel('Amplitude')
                end
                
                % and next you quantify the amount of amp modulation by means of a
                % normalized entropy index (Tort et al PNAS 2008):
                
                MI=(log(nbin)-(-sum((MeanAmp/sum(MeanAmp)).*log((MeanAmp/sum(MeanAmp))))))/log(nbin);
                
                % Add this value to all other all other values
                MI_surr(surr) = MI;
                
            end
            
            disp('200 surrogates computed');
            
            % Calculate average MI over trials
            MI_raw = mean(MI_comb);
            
            % Subtract the mean of the surrogaates from the actual PAC
            % value
            MI_raw = MI_raw-mean(MI_surr);
            
        else
            MI_raw = mean(MI_comb);
        end
        
        % Add to Matrix
        MI_matrix(row1,row2) = MI_raw;
        
        % Show progress of the comodulogram
        if strcmp(diag, 'yes')
            figure(2)
            pcolor(phase(1):1:phase(2),amp(1):2:amp(2),MI_matrix)
            colormap(jet)
            ylabel('Amplitude (Hz)')
            xlabel('Phase (Hz)')
            colorbar
            drawnow
        end
        
        % Go to next Amplitude
        row1 = row1 + 1;
        
        disp(sprintf('Phase: %d Amplitude: %d  MI: %d',k,p,MI_raw));
    end
    % Go to next Phase
    row1 = 1;
    row2 = row2 + 1;
end
end