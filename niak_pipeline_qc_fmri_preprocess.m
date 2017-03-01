function pipe = niak_pipeline_qc_fmri_preprocess(in,opt)
% Generate anatomical and functional figures to QC coregistration
%
% SYNTAX: PIPE = NIAK_PIPELINE_QC_FMRI_PREPROCESS(IN,OPT)
%
% IN.ANAT.(SUBJECT) (string) the file name of an individual T1 volume (in stereotaxic space).
%   Labels SUBJECT are arbitrary but need to conform to matlab's specifications for 
%   field names. 
% IN.FUNC.(SUBJECT) (string) the file name of an individual functional volume (in stereotaxic space)
%   Labels SUBJECT need to be consistent with IN.ANAT. 
% IN.ANAT_TEMPLATE  (string) the file name of the anatomical template used as referene for visual QC.
% IN.FUNC_TEMPLATE  (string) the file name of the functional template to be used as referene for visual QC.
% IN.LAYOUT_ANAT    ((string) the file name of the template layout in stereotaxic space for anattomical QC landmarks.
%    If left empty no layout overlay will be applayed to the anat_template image.
% IN.LAYOUT_FUNC    (string) the file name of the functional template layout in stereotaxic space for functional QC landmarks.
%    If left empty no layout overlay will be applayed to the template image.
% OPT.FOLDER_OUT    (string) where to generate the outputs. 
% OPT.COORD         (array N x 3) Coordinates for the figure. The default is:
%                               [-30 , -65 , -15 ; 
%                                 -8 , -25 ,  10 ;  
%                                 30 ,  45 ,  60];
% OPT.FLAG_DECORATION (boolean, default true) if the flag is true, produce a regular figure
%    with axis, title and colorbar. Otherwise just output the plain mosaic. 
% OPT.FLAG_LAYOUT (boolean, default True) if the flag is "flase", the pipeline will not generate layout over anat and func images
% OPT.PSOM (structure) options for PSOM. See PSOM_RUN_PIPELINE.
% OPT.FLAG_VERBOSE (boolean, default true) if true, verbose on progress. 
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the pipeline will 
%   be generated but no processing will occur.
%
% Note:
%   This pipeline needs the PSOM library to run. 
%   http://psom.simexp-lab.org/
% 
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : visualization, montage, 3D brain volumes

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

psom_gb_vars;

%% Defaults

% Inputs
in = psom_struct_defaults( in , ...
    { 'anat' , 'anat_template' , 'func_template' , 'layout_func' , 'layout_anat', 'func' }, ...
    { NaN    , NaN             , NaN             , ''            , ''           , NaN    });

if ~isstruct(in.anat)
    error('IN.ANAT needs to be a structure');
end

if ~isstruct(in.func)
    error('IN.FUNC needs to be a structure');
end

list_subject = fieldnames(in.anat);
if (length(fieldnames(in.func))~=length(list_subject))||any(~ismember(list_subject,fieldnames(in.func)))
    error('IN.ANAT and IN.FUNC need to have the same field names')
end

% Options 
if nargin < 2
    opt = struct;
end

coord_def =[-30 , -65 , -15 ;... 
            -8 , -25 ,  10 ; ...  
            30 ,  45 ,  60];
opt = psom_struct_defaults ( opt , ...
    { 'folder_out' , 'coord'      , 'flag_decoration',   'flag_test' , 'psom'   , 'flag_layout' , 'flag_verbose' }, ...
    { pwd          , coord_def    , true             ,   false       , struct() , True         , true  });
opt.folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [opt.folder_out 'logs' filesep];

%% Add the summary for the anat_template
pipe = struct;
inj.anat = 'gb_niak_omitted';
inj.func = 'gb_niak_omitted';
inj.anat_template = in.anat_template;
inj.func_template = in.func_template;
inj.layout_anat = 'gb_niak_omitted';
inj.layout_func = 'gb_niak_omitted';
outj.anat = 'gb_niak_omitted';
outj.func = 'gb_niak_omitted';
outj.anat_template = [opt.folder_out 'summary_anat_template.jpg'];
outj.layout_anat_template = 'gb_niak_omitted';
outj.layout_func_template = 'gb_niak_omitted';
outj.layout_anat = 'gb_niak_omitted';
outj.layout_func = 'gb_niak_omitted';
outj.report =  'gb_niak_omitted';
optj.coord = opt.coord;
optj.flag_decoration = opt.flag_decoration;
optj.id = 'MNI152';
pipe = psom_add_job(pipe,'summary_anat_template','niak_brick_qc_fmri_preprocess',inj,outj,optj);

%% Add layout on anat_template
if opt.flag_layout
  inj.anat = 'gb_niak_omitted';
  inj.func = 'gb_niak_omitted';
  inj.template = in.template;
  inj.layout_anat = in.layout_anat;
  outj.anat = 'gb_niak_omitted';
  outj.func = 'gb_niak_omitted';
  outj.template = niak_file_tmp('summary_template.jpg');
  outj.layout_template = [opt.folder_out 'summary_template_layout.jpg'];
  outj.layout_anat = 'gb_niak_omitted';
  outj.report =  'gb_niak_omitted';
  optj.coord = opt.coord;
  optj.flag_decoration = opt.flag_decoration;
  optj.id = 'MNI152_layout';
  pipe = psom_add_job(pipe,'summary_template_layout','niak_brick_qc_fmri_preprocess',inj,outj,optj);
  pipe = psom_add_clean(pipe,'clean_summary_template_layout',outj.template);
else
    opt.flag_layout = false;
end

if opt.flag_layout == true
   template = pipe.summary_template_layout.files_out.layout_template;
   else
   template = pipe.summary_template.files_out.template;
end
   
%% Add the generation of summary images for all subjects
n_shift = 0;
for ss = 1:length(list_subject)
    clear inj outj optj
    subject = list_subject{ss};
    if opt.flag_verbose
       fprintf('Adding job: QC report for subject %s\n',subject);
    end
    inj.anat = in.anat.(subject);
    inj.func = in.func.(subject);
    inj.template = in.template;
    inj.layout = in.template_layout;
    outj.anat = [opt.folder_out 'summary_' subject '_anat.jpg'];
    outj.func = [opt.folder_out 'summary_' subject '_func.jpg'];
    if opt.flag_layout == true
       outj.template = niak_file_tmp('summary_template.jpg');
       outj.layout_template = 'gb_niak_omitted';;
       outj.layout_anat = [opt.folder_out 'summary_' subject '_anat_layout.jpg'];
    else
       outj.template = 'gb_niak_omitted';
       outj.layout_anat = 'gb_niak_omitted';
       outj.layout_template = 'gb_niak_omitted';
    end   
    outj.report =  [opt.folder_out 'report_coregister_' subject '.html'];
    optj.coord = opt.coord;
    optj.flag_decoration = opt.flag_decoration;
    optj.flag_layout = opt.flag_layout;
    optj.id = subject;
    optj.template = template;
    pipe = psom_add_job(pipe,['report_' subject],'niak_brick_qc_fmri_preprocess',inj,outj,optj);
    if opt.flag_layout == true
       pipe = psom_add_clean(pipe,(['clean_report_' subject]),outj.template); 
    end
    %% generate gif image for zooniverse platform
    if opt.flag_gif == true
    
       % anat2template
       ing.img1 = pipe.(['report_' subject]).files_out.layout_anat;
       ing.img2 = template;
       outg = [path_gif 'summary_' subject '_anat2template.gif'];
       optg.ratio = opt.gif.ratio;
       optg.alpha = opt.gif.alpha;
       optg.transition_delay = opt.gif.transition_delay;
       pipe = psom_add_job(pipe,['gif_report_anat2template_' subject],'niak_brick_img2gif',ing,outg,optg);
       
       % func2anat
       ing.img1 = pipe.(['report_' subject]).files_out.func;
       if opt.flag_layout == true
          ing.img2 = pipe.(['report_' subject]).files_out.layout_anat;
       else 
          ing.img2 = pipe.(['report_' subject]).files_out.anat;
       end
       outg = [path_gif 'summary_' subject '_func2anat.gif'];
       optg.ratio = opt.gif.ratio;
       optg.alpha = opt.gif.alpha;
       optg.transition_delay = opt.gif.transition_delay;
       pipe = psom_add_job(pipe,['gif_report_func2anat_' subject],'niak_brick_img2gif',ing,outg,optg);
       
       % Manifest file creation
       if ss == 1 
         tab{ss,1} = [subject '_anat'] ;
         tab{ss,2} = [ 'summary_' subject '_anat2template.gif'];
         tab{ss+1,1} = [subject '_func'];
         tab{ss+1,2} = [ 'summary_' subject '_func2anat.gif'];
       else
         tab{ss+n_shift,1} = [subject '_anat'] ;
         tab{ss+n_shift,2} = [ 'summary_' subject '_anat2template.gif'];
         tab{ss+n_shift+1,1} = [subject '_func'] ;
         tab{ss+n_shift+1,2} = [ 'summary_' subject '_func2anat.gif'];
       end
       n_shift = n_shift+1;
    end
end

%% Save manifest file
if opt.flag_gif == true
   header_labels = {'subject_ID','images'};
   tab_final = [header_labels ; tab];
   niak_mkdir(path_gif);
   file_name = [path_gif 'zooniverse_manifest_file.csv'];
   niak_write_csv_cell(file_name,tab_final);
end

%% Add a spreadsheet to write the QC. 
clear inj outj optj
outj = [opt.folder_out 'qc_report.csv'];
optj.list_subject = list_subject;
pipe = psom_add_job(pipe,'init_report','niak_brick_init_qc_report','',outj,optj);

%% Generate file names and links for the wrappers
file_wrap = cell(length(list_subject),1);
list_content = cell(length(list_subject),1);
list_wrap{1} = [opt.folder_out 'index.html'];
list_links = sprintf('<li><a href="index.html">Group summary</a></li>\n');
list_content{1} = sprintf([ '<p>\n Report on quality of registration for %i subjects prepared by %s, using NIAK on the system %s, on %s.\n </p> \n ' ...
                                           '<p>\n Click on a subject ID in the left navigation bar to access an individual report. \n</p>\n' ...
                                           '<p>\n Hover on and off a picture to flip between the source and the target of  the registration.\n</p>\n'], ...
                                           length(list_subject),gb_psom_user,gb_psom_localhost,datestr(now));
for ss = 1:length(list_subject)
    subject = list_subject{ss};
    list_wrap{ss+1} = [opt.folder_out 'wrapper_'  subject '.html'];
    list_links = [list_links sprintf('<li><a href="%s">%s</a></li>\n',['wrapper_'  subject '.html'],subject)];
    list_content{ss+1} = sprintf('<object class="internal" type="text/html" data="%s"></object>\n',['report_coregister_' subject '.html']);
end

%% Read html template
file_self = which('niak_pipeline_qc_fmri_preprocess');
path_self = fileparts(file_self);
file_html = [path_self filesep 'niak_index_qc_fmri_preprocess.html'];
hf = fopen(file_html,'r');
str_html = fread(hf,Inf,'uint8=>char')';
fclose(hf);

%% Generate the wrappers
if opt.flag_verbose 
    fprintf('Adding jobs to generate wrappers html...\n')
end
for ww = 1:length(list_wrap)
    file_wrap = list_wrap{ww};
    if ww==1
       name_job = 'index_html';
       links_ww = strrep(list_links,'<li><a href="index.html">Group summary</a></li>','<li><a class="active" href="index.html">Group summary</a></li>');
    else
       subject = list_subject{ww-1}; 
       name_job = ['wrapper_' subject];
       links_ww = strrep(list_links,sprintf('<li><a href="%s">%s</a></li>\n',['wrapper_'  subject '.html'],subject),sprintf('<li><a class="active" href="%s">%s</a></li>\n',['wrapper_'  subject '.html'],subject));
    end 
    str_write = strrep(str_html,'$LINKS',links_ww);
    prev_subject = list_subject{max(1,ww-2)};
    next_subject = list_subject{min(length(list_subject),ww)};
    str_write = strrep(str_write,'$PREVIOUSID',prev_subject);
    str_write = strrep(str_write,'$PREVIOUS',['wrapper_'  prev_subject '.html']);
    str_write = strrep(str_write,'$NEXTID',next_subject);
    str_write = strrep(str_write,'$NEXT',['wrapper_'  next_subject '.html']);
    str_write = strrep(str_write,'$CONTENT',list_content{ww});
    pipe.(name_job).files_out = file_wrap;
    pipe.(name_job).opt = str_write;
    pipe.(name_job).command = 'hf = fopen(files_out,''w+''); fprintf(hf,''%s'',opt); fclose(hf);';
end

if ~opt.flag_test
    psom_run_pipeline(pipe,opt.psom);
end
