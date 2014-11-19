function illustrate( filenames, illustrate_epochs, epoch_length, margin )
% illustrate( filenames, illustrate_epochs, epoch_length ) 
% Produce PDF illustrations of processing involved in producing an index
%
% 'filenames' is a structure with the filenames for the signal, waveform
% trains, and indices
%
% 'illustrate_epochs' is a list of epoch numbers for which a blown up figure
% will be produced
%
% 'epoch_length' is the the length of an epoch in samples


assert( length( illustrate_epochs ) <= 26 ...
    , 'Cannot plot more than 26 epochs per episode' );

%******** whole-episode plot *********

% open episode EEG file  
hdr = edfopen( filenames.signal_file );
signal = edfread(hdr,0,hdr.nsamples);

% set up figure for printing
fig1 = figure;  
set(fig1,'Units','normalized','Position',[0.15 0 0.7 0.5] ...
    , 'PaperUnits', 'normalized', 'PaperPosition',[0, 0, 1.8, 0.3*sqrt(sum(hdr.roles~='D'))]);

% high-pass filtration (unnecessary for Ripple data)
k = myhamm(101); k = k/sum(k);
signal = signal - conv2(signal,k,'same');

% find optimal time unit to make approximately nticks along time axis
nticks = 12;
timepoints1 = (0:hdr.nsamples-1)/hdr.samples_per_second;
timesteps = [1 5 15 30 60 120 300 900 1800 3600];
[m,i] = min( abs( 1 - (nticks*timesteps / hdr.nsamples * hdr.samples_per_second ) ) );
timestep = timesteps(i);

time_unit = 'seconds';
timescale = 1;
if timestep >= 30
    timescale = 60;
    time_unit ='minutes';
end
if timestep >= 3600
    timescale = 3600;
    time_unit = 'hours';
end
xticks = (0:timestep:max(timepoints1))/timescale;
timepoints1 = timepoints1/timescale;

%select S and N channels only.  D channels are not included
selection = find(hdr.roles ~= 'D');
channelnames = hdr.channelnames(selection,:);
signal = signal(selection,:);

% plot EEG signals 
yspacing = 2000;
for i=1:size(signal,1)
    level = yspacing*i;
    
    % plot EEG zero line
    plot( timepoints1, timepoints1*0+level, 'Color', [0.3 0.3 0.3], 'LineWidth', 0.5 ); 
   
    % plot EEG trace
    plot( timepoints1, signal(i,:)+level, 'Color', [0.0 0.0 0.0], 'LineWidth', 0.25 ); hold on;

    text( timepoints1(1), level, [strtrim(channelnames(i,:)) ' '], 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right', 'FontName', 'Arial', 'FontSize', 12);
end


% read metrics
fmetrics = fopen  ( filenames.metrics_file, 'r');
assert( fmetrics ~= -1,  ['Could not open ' filenames.metrics_file] );
line = fgetl(fmetrics);  %throw away first line
metrics = [];
while ~feof(fmetrics)
    metrics = [metrics; strread( fgetl(fmetrics), '', 'delimiter', ',' )];
end


% plot metrics
metrics_scale = 5000;
metrics_offset = -4800;

% plot metrics axis and threshlold line
plot(timepoints1, timepoints1*0+metrics_offset, 'Color', [0.2 0.2 0.2], 'LineWidth', 0.25);
plot(timepoints1, timepoints1*0+metrics_offset+metrics_scale*0.15, '-', 'Color', [0.2 0.2 0.2], 'LineWidth', 1);

% compute the time axis by averaging the first two columns: (epoch_start+epoch_end)/2
timepoints2 = metrics(:,1)/hdr.samples_per_second/timescale;

% plot density 
%plot( timepoints2,10000*metrics(:,3)+Y(2), 'c', 'LineWidth', 3);

% plot rhythmicity
%plot( timepoints2, metrics_scale*metrics(:,4)+metrics_offset, 'gv-', 'LineWidth', 1);

% plot simplicity
%plot( timepoints2, metrics_scale*metrics(:,5)+metrics_offset, 'r*-', 'LineWidth', 1);

% plot composite
plot( timepoints2, metrics_scale*metrics(:,2)/1024+metrics_offset, 'ks-', 'LineWidth', 1);

% plot grid lines
axis off;

ylims = [metrics_offset,level+1000];
ylims = ylims - [0.08*(ylims(2)-ylims(1)) 0];  %expand by at the bottom to make room for labels

for x = xticks 
    plot([x x], [metrics_offset,level+1000], 'Color', [0.4 0.4 0.5], 'LineWidth', 0.25);
    text(x,metrics_offset, num2str(x), 'VerticalAlignment', 'top', 'HorizontalAlignment', 'center', 'FontName', 'Arial', 'FontSize',11);
end
text(max(timepoints2),ylims(1), sprintf('Episode time (%s)',time_unit), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontName','Arial','FontSize',12)
ylim(ylims);


% plot epoch boxes
ftrains = fopen( filenames.train_file  , 'r', 'ieee-le' );
assert( ftrains ~= -1,  ['Could not open ' filenames.train_file] );
nchannels = fread( ftrains, 1, 'uint8'); 

letter = 'A';
for iepoch = 1:inf  %epoch number
    if end_of_file(ftrains)
        break;
    end
    
    start_time = fread( ftrains, 1, 'uint32');
    trains = [];
    while fread( ftrains, 1, 'uint8' )
        trains = [trains read_one_train( ftrains, nchannels )];
    end
    simplicity = fread( ftrains, 1, 'uint16');
     
    if ismember( iepoch, illustrate_epochs )
        xywh = [timepoints1(start_time+1),100,diff( timepoints1(start_time+[1 epoch_length])), ylims(2)-150 ];
        rectangle('Position', xywh, 'EdgeColor', [0.8 0.3 0.3]);
        text(xywh(1),xywh(2),[' ' letter],'VerticalAlignment','Bottom','HorizontalAlignment','left','FontName','Arial','FontSize',14,'Color',[0.4, 0.1 0.1] );
        letter = char(letter+1);
    end
end

drawnow;
print('-depsc', [filenames.figures '_whole_episode'] );
fclose(fmetrics);
fclose(ftrains);






% ***************** plot selected epochs ***************************

ftrains = fopen( filenames.train_file  , 'r', 'ieee-le' );
assert( ftrains ~= -1,  ['Could not open ' filenames.train_file] );
nchannels = fread( ftrains, 1, 'uint8'); 

colors = [1.0 0.5 0.5;  0.4 0.9 0.4;  0.5 0.5 1.0;  0.5 0.6 1.0];
markers = ['x*ov'];
letter = 'A';

for iepoch = 1:inf  %epoch number
    if end_of_file(ftrains)
        break;
    end

    start_time = fread( ftrains, 1, 'uint32');
    trains = [];
    while fread( ftrains, 1, 'uint8' ) 
        trains = [trains read_one_train( ftrains, nchannels )];
    end
    simplicity = fread( ftrains, 1, 'uint16');
    
    epoch_signal = signal(:,start_time+(1:epoch_length));
    scale = (1500/max( max( abs( epoch_signal ))))^0.7;  %not quite normalize

    if ismember( iepoch, illustrate_epochs )        
        assert(length(trains)<=4,'Cannot plot more than four trains');
       
        % set up figure for printing
        fig2 = figure;  
        set(fig2,'Units','normalized','Position',[0.15 0 0.7 0.5] ...
            ,'PaperUnits', 'normalized', 'PaperPosition',[0, 0, 1.8, 0.6]);
        for i=1:size(signal,1)
            level = i*2000;
            for itrain = 1:length(trains)
                train = trains(itrain);
                n = size(train.waveform,2);
                ix = -floor(n/2)+(0:n-1);  % relative index into signal
                for idx=train.idx'
                    sel = find(train.waveform(i,:)~=0, 1, 'first'):find(train.waveform(i,:)~=0, 1, 'last');                    
                    plot( idx+ix(sel)+1, scale*train.waveform(i,sel)+level, 'Color', colors(itrain,:), 'LineWidth',2 ); hold on;
                end
                plot( train.idx+1, 0, markers(itrain), 'Color', min(1,max(0,1-(1-colors(itrain,:))*1.5)), 'MarkerSize', 12 );
            end
            plot( scale*epoch_signal(i, :)' + level, 'k' );
            plot(     0*epoch_signal(i, :)' + level, 'Color', [0.5 0.5 0.5]);
            str = [strtrim(channelnames(i,:)) ' '];
            text( 0, level, str, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right', 'FontName', 'Arial', 'FontSize', 12);

        end

   
        axis off;
        
        % plot timescale  bar
        plot([0 hdr.samples_per_second/2], level+1000*[1 1], 'k', 'LineWidth', 4 );
        h = text(hdr.samples_per_second/4, level+1000, '500 ms', 'VerticalAlignment', 'bottom', 'HorizontalAlignment','center', 'FontName', 'Arial', 'FontSize',16);
     %   str = sprintf('Epoch %s: Simplicity = %2.3f   Rhythmicity = %2.3f   Composite = %2.3f', letter, metrics(iepoch,5), 5*metrics(iepoch,4), metrics(iepoch,6));
     %  text( hdr.samples_per_second, level+1000, str, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'FontName', 'Arial', 'FontSize', 16);


        print('-depsc', [filenames.figures '_epoch_' letter]);
        close(fig2);

        letter = char(letter+1);
    end
end

fclose(fmetrics);
close(fig1);