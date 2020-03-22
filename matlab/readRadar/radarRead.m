%% ATTENTION！Please modify the comPortString in line 29 and line 36, according your port configuration

% read config file and send config to radar
configfile = "./shortRange.cfg"
[DATA_sphandler, UART_sphandler, ConfigParameters] = radarSetup16XX(configfile)

% container of output data from DATA_sphandler
out = []

for i=1:1000000
	cout = fread(DATA_sphandler, 1, 'uint8');
	out = [out; cout];
end

fprintf(UART_sphandler, 'sensorStop')
fclose(DATA_sphandler)
fclose(UART_sphandler)
save('data.mat')



function [DATA_sphandle,UART_sphandle, ConfigParameters] = radarSetup16XX(configfile)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%         CONFIGURE SERIAL PORT          %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% UART COM PORT:
comPortString = 'COM4';
UART_sphandle = serial(comPortString,'BaudRate',115200);
set(UART_sphandle,'Parity','none')
set(UART_sphandle,'Terminator','LF')
fopen(UART_sphandle);

%%%% DATA COM PORT:
comPortString = 'COM3';
DATA_sphandle = serial(comPortString,'BaudRate',921600);
set(DATA_sphandle,'Terminator', '');
set(DATA_sphandle,'InputBufferSize', 65536);
set(DATA_sphandle,'Timeout',10);
set(DATA_sphandle,'ErrorFcn',@dispError);
set(DATA_sphandle,'BytesAvailableFcnMode','byte');
set(DATA_sphandle,'BytesAvailableFcnCount', 2^16+1);%BYTES_AVAILABLE_FCN_CNT);
set(DATA_sphandle,'BytesAvailableFcn',@readUartCallbackFcn);
fopen(DATA_sphandle);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%        READ CONFIGURATION FILE         %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


config = cell(1,100);
fid = fopen(configfile, 'r');
if fid == -1
    fprintf('File %s not found!\n', configfile);
    return;
else
    fprintf('Opening configuration file %s ...\n', configfile);
end
tline = fgetl(fid);
k=1;
while ischar(tline)
    config{k} = tline;
    tline = fgetl(fid);
    k = k + 1;
end
config = config(1:k-1);
fclose(fid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%        SEND CONFIGURATION TO SENSOR         %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mmwDemoCliPrompt = char('mmwDemo:/>');

%Send CLI configuration to IWR14xx
fprintf('Sending configuration from %s file to IWR16xx ...\n', configfile);

for k=1:length(config)
    command = config{k};
    fprintf(UART_sphandle, command);
    fprintf('%s\n', command);
    echo = fgetl(UART_sphandle); % Get an echo of a command
    done = fgetl(UART_sphandle); % Get "Done"
    prompt = fread(UART_sphandle, size(mmwDemoCliPrompt,2)); % Get the prompt back
end


end