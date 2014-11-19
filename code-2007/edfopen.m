function hdr = edfopen( filename )
% edfopen( filename )
% Reads EDF header of episode file.
% The sample rate must be the same for all channels
% Reads signal roles (S, R, or N) from the reserved channel field
% Reads sensory xy coordinates of each channel from the reserved field

f = fopen(filename,'r','ieee-le');
assert( f~=-1, sprintf('%s not found', filename) )

hdr.filename = filename;

% discard patient and session information
fread(f, 8,'uchar');  %EDF version
fread(f,80,'uchar');  %patient information
fread(f,80,'uchar');  %recording information
hdr.start_date = fread(f, 8,'uchar=>char')';  % start date
hdr.start_time = fread(f, 8,'uchar=>char')';  % start time

% read header_size
hdr.header_size = str2num(fread(f,8,'uchar=>char')');
fseek(f,44,0); % reserved, not used


hdr.nframes = str2num(fread(f,8,'uchar=>char')');
hdr.frame_duration = str2num(fread(f,8,'uchar=>char')');
hdr.nchannels = str2num(fread(f,4,'uchar=>char')');
hdr.channelnames = fread(f,[16,hdr.nchannels],'uchar=>char')';

% extraneous information 
hdr.transducer = fread(f,[80,hdr.nchannels],'uchar=>char')'; 
hdr.physdime   = fread(f,[ 8,hdr.nchannels],'uchar=>char')'; 
hdr.physmin    = fread(f,[ 8,hdr.nchannels],'uchar=>char')'; 
hdr.physmax    = fread(f,[ 8,hdr.nchannels],'uchar=>char')'; 
hdr.digimin    = fread(f,[ 8,hdr.nchannels],'uchar=>char')'; 
hdr.digimax    = fread(f,[ 8,hdr.nchannels],'uchar=>char')'; 
hdr.prefilt    = fread(f,[80,hdr.nchannels],'uchar=>char')'; 


%read samples per frame in each channel
hdr.samples_per_frame = str2num(fread(f,[8,hdr.nchannels],'uchar=>char')');   

%read positions of sensors on the illustration of a head
reserved = fread(f,[32,hdr.nchannels],'uchar=>char')';
hdr.roles = reserved(:,1);
hdr.sensorxy = str2num( reserved(:,3:end) );

assert( ftell(f) == hdr.header_size, 'Header size does not match file position');

assert( all( hdr.samples_per_frame == max(hdr.samples_per_frame)) ...
    , 'All episode channels must have same samples_per_frame');

hdr.samples_per_frame = max(hdr.samples_per_frame);
hdr.samples_per_second = hdr.samples_per_frame/hdr.frame_duration;
hdr.nsamples = hdr.nframes*hdr.samples_per_frame;

fclose(f);