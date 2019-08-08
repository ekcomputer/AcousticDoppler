% Riv2xls
% By Ethan Kyzivat and Ted Langhorst, with suggestions from Wayana Dolan
% and Lincoln Pitcher

% August 2018
% Written on a moving boat in the Peace-Athabasca Delta

%     A script to pull data and metadata from a RiverSurveyorLive Matlab
%     export and write them to an excel file.  Used to semi-automatically perform
%     quality control on bathymetry and discharge data.  Prompts user input to select
%     directory (typically named by the day's date, or following day's date
%     if duration exceeds midnight UTC).  It is necessary to export the
%     day's files from River Surveryor Live (RSL, ctrl + t, Matlab export all).  If you set
%     usesummfile equal to 1, then you must export the summary file from
%     RS.  (ctrl + s), make sure all are highlighed red (default), and save
%     as ascii.  The file name
%     doesn't matter, but the extension must be .dis
%     Output QC file appears in this directory.

% Version History

%     Version 10 intelligently decides whethr or not to correct for the
%     time firmware glitch, based on whether the actual date is August 12
%     or earlier.  Also has an error message if number of lines in .dis
%     file are different from number of .mat files

%     Version 9 ensures that each line of the .dis files is matched to
%     proper file name AND can parse more thabn one .dis files, so no
%     manual splicing is needed!  Also fixes bug in end date (introduced in
%     version 8).

%     Version 8 corrects for firmware glitch that gives improper date.
%     Also doesn't report mean veloc unless using the .dis file

%     Version 7 saves lat/long, adds error message for improper loading.

%     Version 6 fixes boat:water ratio inversion; only looks at HDOP and
%     GPS_quality within transect, not at edges; stops auto-populating
%     Track reference field (since these values are not         in .mat file)

clear
close all
usesummfile=1; % switch to 0 if no summ file

startDir=pwd;

FieldNames= {'Filename',	'Measurement_type',	'Location',	'Measurement_number',...
    'Comments', 'Party', 'Boat_motor', 'Date',	'Start_time',...
    'End_time',	'Time_zone',	'Transducer_depth',	'Mag_declination',...
    'Track_ref',	'Start_bank',	'GPS_quality',	'HDOP',	'Voltage',...
    'L_edge_dist',	'R_edge_dist',	'L_edge_Qual','R_edge_Qual','Edge_notes',	'Depth_ref_invalid',...
    'Depth_notes',	'Depth_reference',	'Track_ref_invalid',	'Veloc_vector',...
    'Veloc_SNR',	'Width',	'Area',	'Veloc_avg',	'Boat_veloc_avg','Boat_water_ratio',...
    'Per_Measured', 'Keep_or_remove',...
    'Final_notes',	'Quality',	'Latitude', 'Longitude', 'Q',...
    'Mat_export'};

% fieldNames = {"File_Name"}

%%
disp('Good day!  Select working directory.')
workingFolder=uigetdir;
cd(workingFolder)
k = dir("*.mat");
if isempty(k)
    disp('You need to export the .mat files from RiverSurveyorLive, you idiot.')
    return
end
use_time_offset=0;
for i = 1:numel(k)
    load(k(i).folder + "\"+ k(i).name);
    sample=1:length(System.Sample);
    val{i,1} = [k(i).name(1:end-4)];
    val{i,2} ='';
    val{i,3} = SiteInfo.Site_Name;
    val{i,4} = SiteInfo.Meas_Number'';
   
    val{i,5} = SiteInfo.Comments;
    val{i,6} = SiteInfo.Party;
    val{i,7} = SiteInfo.Boat_Motor;
    
    val{i,8} = datetime(k(i).name(1:8), 'InputFormat', 'yyyyMMdd');%date
%     val{i,6} =datetime(GPS.Utc(1),'ConvertFrom','excel',...
%         'TimeZone', 'America/Chicago', 'Format','HH:mm:ss') ;
%     val{i,7} =datetime(GPS.Utc(end),'ConvertFrom','excel',...
%         'TimeZone', 'America/Chicago', 'Format','HH:mm:ss') ;
    if str2double(char(datetime(val{i,8}, 'Format', 'yyyyMMdd')))   < 20180803
        time_offset=37.75;
        use_time_offset=1;
    else time_offset=0; % 20180812 was first day of time glitch
    end
    val{i,9} = char(datetime(RawGPSData.GgaTimeStamp(1), 'ConvertFrom', 'epochtime', 'Epoch','2000-01-01',...
        'Format','HH:mm:ss')+minutes(time_offset));
    val{i,10} = char(datetime(RawGPSData.GgaTimeStamp(end,1), 'ConvertFrom', 'epochtime', 'Epoch','2000-01-01',...
        'Format','HH:mm:ss')+minutes(time_offset));
    val{i,11} = -6;
    val{i,12} = round(Setup.sensorDepth,2);
    val{i,13} = round(Setup.magneticDeclination, 2);
    val{i,14} = mode(Summary.Track_Reference);
    if val{i,14}==2
        val{i,14}='GPS-GGA';
    elseif val{i,14}==3
        val{i,14}='GPS-VTG';
    elseif val{i,14}==1
        val{i,14}='BT';
    else warning('Unexpected track reference code.')
    end
    val{i,15} = Setup.startEdge;
    if val{i,15}==0
        val{i,15}='Left';
    elseif val{i,15}==1
        val{i,15}='Right';
    end
    trans=sample(System.Step==3); %transect samples (not edges)
    val{i,16} = min(GPS.GPS_Quality(trans));
    if max(GPS.HDOP(trans))<2
        val{i,17} = 1;
    else
        val{i,17} = 0;
    end
    val{i,18} = round(System.Voltage(end),2);
    if Setup.startEdge==0
        val{i,19} = Setup.Edges_0__DistanceToBank;
        val{i,20} = Setup.Edges_1__DistanceToBank;
    elseif Setup.startEdge==1
        val{i,19} = Setup.Edges_1__DistanceToBank;
        val{i,20} = Setup.Edges_0__DistanceToBank;
    else
        warning('Unexpected start edge code.')
    end
%     System.Sample=System.Sample(2:end);
    edge1=sample(System.Step==2);
    edge2=sample(System.Step==4);
    edge1cells=Summary.Cells(edge1);
    edge2cells=Summary.Cells(edge2);
    
    if Setup.startEdge==0
       if length(edge1)>=10 & min(edge1cells)>=2
            val{i,21} = 1; %edge quality
       else val{i,21} = 0;
       end
       if length(edge2)>=10 & min(edge2cells)>=2
            val{i,22} = 1;
       else val{i,22} = 0;
       end
    elseif Setup.startEdge==1
       if length(edge1)>=10 & min(edge1cells)>=2
            val{i,22} = 1;
       else val{i,22} = 0;
       end
       if length(edge2)>=10 & min(edge2cells)>=2
            val{i,21} = 1;
       else val{i,21} = 0;
       end
    else
        warning('Unexpected code.')
    end
    val{i,23} = ''; % edge notes
    val{i,24} = ''; % depth-ref-invalid
    val{i,25} = '';% depth notes
    val{i,26} = Setup.depthReference;% depth ref
    if val{i,26}==0
        val{i,26}='VB';
    elseif val{i,26}==1
        val{i,26}='BT';
    else warning('Unexpected depth reference code.')
    end
    val{i,27} = ''; %track ref invalid
    val{i,28} = ''; %Veloc vector
    val{i,29} = ''; %velocity_SNR
    val{i,30} = ''; %width?
    val{i,31} = Summary.Area;
    val{i,32} = ''; %mean(Summary.Mean_Vel(:,1)); % need to be more precise
    val{i,33} = '';
    val{i,34} = '';
    val{i,35} = ''; % % measured
    val{i,36} = ''; %keep or remove
    val{i,37} = ''; %remove notes
    val{i,38} = ''; %quality
    val{i,39} = mean(GPS.Latitude); %lat
    val{i,40} = mean(GPS.Longitude); % long
    val{i,41} = Summary.Total_Q(end);
    val{i,42} = '';%Mat export
%     val{i,33} = 
%     val{i,34} = 
%     val{i,35} = 
%     val{i,36} = 
%     val{i,37} = 
%     val{i,38} = 
    
end
if use_time_offset==1
    disp('Time offset applied to correct for firmware time glitch.')
end
%% load from .summ file
if usesummfile
    summfile=cellstr(ls('*.dis'));
    fprintf('%u .dis files found.\n', length(summfile))

    if isempty(summfile)
        disp('You need to export the .dis files from RiverSurveyorLive, you idiot.')
        disp('ctrl-s and export to ascci.  OR: make sure only one .dis in directory.')
        disp('You can give it any name.')
        disp('OR: set usesummfile=0 at beginning of script.')
        return
    end
    for n=1:length(summfile)
        fid=fopen(summfile{n}, 'r');
        summ=textscan(fid, '%s', 'Delimiter', '\n');
        summheadings=textscan(summ{:}{54}, '%s', 'Delimiter', '\t');
        summheadings=summheadings{:};
        fclose(fid);
        summ={summ{:}{55:end-19}};
        fprintf('Number of entries in .dis file number %u: %u\n', n, length(summ))
        fprintf('Number of .mat files: %u\n', numel(k))
    %     if length(summ)~=numel(k)
    %         disp('The length of your .dis file is not equal to the number of')
    %         disp('.mat files...')
    %         fprintf('.Dis length: %u\n', length(summ))
    %         fprintf('.mat files: %u\n', numel(k))
    %         return
    %     end
        for i= 1:length(summ)
            summp{i}=textscan(summ{i}, '%s', 'Delimiter', '\t');
            summp{i}=summp{i}{:};
        end
        for i=1:length(summ)
            summfilename= summp{i}{2}(1:end-4); % name as reported in .dis file
            j_index=contains({val{:,1}}, summfilename);
            j=find(j_index);
            val{j,30} =summp{i}{10}; % width
            val{j,33} = summp{i}{12}; %boat speed
            val{j,32} = summp{i}{13}; %updated mean speed
            val{j,34} = str2double(val{j,33})./str2double(val{j,32}); %ratio
            val{j,35} = summp{i}{21}; % % measured
        end
    end
end 

    %% make table for export
val_table=cell2table(val, 'VariableNames', FieldNames);
%xlswrite(fileName,[fieldNames; name])]

%% format and save excel file
% strings=textscan(k(1).folder, '%s', 'Delimiter', '\');
% datestr=strings{1}{end};
datestr=char(datetime(val{1,8}, 'Format', 'yyyyMMdd'));
fileName = [workingFolder,'\QC_', datestr,'.xlsx'];
Continue=1;
if exist(fileName)==2
    Continue=input('QC file in this folder already found.  Overwrite? (1/0) ');
end

if Continue==1
    writetable(val_table, fileName);
    fprintf('QC table written: %s\n', fileName);
else
    disp('No files written.')
end
cd(startDir)