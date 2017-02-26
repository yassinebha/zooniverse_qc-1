function pipeline = zoo_report_fmri_preprocess(in,opt)
% Generate images for the zooniverse brain match report
%
% SYNTAX: PIPE = ZOO_REPORT_FMRI_PREPROCESS(IN,OPT)
%
% IN.IND (structure)
%   with the following fields:
%   ANAT.(SUBJECT) (string) the file name of an individual T1 volume (in stereotaxic space).
%   FUNC.(SUBJECT) (string) the file name of an individual functional volume (in stereotaxic space)
%
% IN.GROUP (structure)
%   with the following fields:
%   AVG_FUNC (string) the file name of the average BOLD volume of all subjects,
%     after non-linear coregistration in stereotaxic space.
%   MASK_FUNC_GROUP (string) the file name of the group mask for BOLD data,
%     in non-linear stereotaxic space.

% IN.TEMPLATE (structure)
%   with the following fields:
%   ANAT (string) the file name of the template used for registration in stereotaxic space.
%   FMRI (string)the file name of the template used to resample fMRI data.
%   ANAT_OUTLINE (string, default anatomical symmetric outline)
%     the f'' name of a b in'' masks, highlighting regions for coregistration.
%   FUNC_OU''NE (string,  de''lt functional symmetric outline)
%     the file name of a binary masks, highlighting regions for coregistration.
%
% OPT (structure)
%   with the following fields:
%   FOLDER_OUT (string) where to generate the outputs.
%   COORD (array N x 3) Coordinates for the registration figures.
%     The default is:
%     [-30 , -65 , -15 ;
%       -8 , -25 ,  10 ;
%       30 ,  45 ,  60];
%   TYPE_OUTLINE (string, default 'sym') what type of registration landmarks to use (either
%     'sym' for symmetrical templates or 'asym' for asymmetrical templates).
%   PSOM (structure) options for PSOM. See PSOM_RUN_PIPELINE.
%   FLAG_VERBOSE (boolean, default true) if true, verbose on progress.
%   FLAG_TEST (boolean, default false) if the flag is true, the pipeline will
%     be generated but no processing will occur.
%
% Note:
%   Labels SUBJECT, SESSION and RUN are arbitrary but need to conform to matlab's
%   specifications for field names.
%
%   This pipeline needs the PSOM library to run.
%   http://psom.simexp-lab.org/
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de griatrie de Montral, 2016.
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

%% PSOM/NIAK variables
psom_gb_vars;
niak_gb_vars;

%% Defaults

% Inputs
in = psom_struct_defaults( in , ...
    { 'ind' , 'group' , 'template' }, ...
    { NaN   , NaN     , NaN        });


in.ind = psom_struct_defaults( in.ind , ...
    { 'anat' , 'func' }, ...
    { NaN    , NaN    });

in.group = psom_struct_defaults( in.group , ...
    { 'avg_func' , 'mask_func_group' }, ...
    { NaN        , NaN               });

in.template = psom_struct_defaults( in.template , ...
    { 'anat' , 'func' , 'anat_outline' , 'func_outline'}, ...
    { NaN    , ''     , ''             , ''           });

if ~isstruct(in.ind.anat)
    error('IN.IND.ANAT needs to be a structure');
end

if ~isstruct(in.ind.func)
    error('IN.IND.FUNC needs to be a structure');
end

list_subject = fieldnames(in.ind.anat);

if (length(fieldnames(in.ind.func))~=length(list_subject))||any(~ismember(list_subject,fieldnames(in.ind.func)))
    error('IN.IND.ANAT and IN.IND.FUNC need to have the same field names')
end

%% Options
if nargin < 2
    opt = struct;
end
coord_def =[-30 , -65 , -15 ;
             -8 , -25 ,  10 ;
             30 ,  45 ,  60];
opt = psom_struct_defaults ( opt , ...
    { 'type_outline' , 'folder_out' , 'coord'   , 'flag_test' , 'psom'   , 'flag_verbose' }, ...
    { 'sym'          , pwd          , coord_def , false       , struct() , true           });

opt.folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [opt.folder_out 'logs' filesep];

% Define outline
if ~ismember(opt.type_outline,{'sym','asym'})
    error(sprintf('%s is an unknown type of outline',opt.type_outline))
end

if isempty(in.template.anat_outline)
  file_outline_anat = [GB_NIAK.path_niak filesep 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_' opt.type_outline '_09a_anat_outline_registration.mnc.gz'];
else
  file_outline_anat = in.template.anat_outline;
end

if isempty(in.template.func_outline)
  file_outline_func = [GB_NIAK.path_niak filesep 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_' opt.type_outline '_09a_func_outline_registration.mnc.gz'];
else
  file_outline_func = in.template.func_outline;
end

%% Copy and update the report templates
pipeline = struct;
clear jin jout jopt
niak_gb_vars
path_template = [GB_NIAK.path_niak 'reports' filesep 'fmri_preprocess' filesep 'templates' filesep ];
jin = niak_grab_folder( path_template , {'.git',[path_template 'motion'],[path_template 'registration'],[path_template 'summary'],[path_template 'group']});
jout = strrep(jin,path_template,opt.folder_out);
jopt.folder_out = opt.folder_out;
pipeline = psom_add_job(pipeline,'cp_report_templates','niak_brick_copy',jin,jout,jopt);

%% Generate template montage images
clear jin jout jopt
jin.target = in.template.anat;
jopt.coord = opt.coord;
% Template anat
jin.source = in.template.anat;
jout = [opt.folder_out 'group' filesep 'template_anat_stereotaxic_raw.png'];
jopt.colormap = 'gray';
jopt.colorbar = false;
jopt.limits = 'adaptative';
jopt.flag_decoration = false;
pipeline = psom_add_job(pipeline,'montage_template_anat','niak_brick_vol2img',jin,jout,jopt);
% Template func
if ~isempty(in.template.func)
  jin.source = in.template.func;
  jout = [opt.folder_out 'group' filesep 'template_func_stereotaxic_raw.png'];
  jopt.colormap = 'gray';
  jopt.colorbar = false;
  jopt.limits = 'adaptative';
  jopt.flag_decoration = false;
  pipeline = psom_add_job(pipeline,'motage_template_func','niak_brick_vol2img',jin,jout,jopt);
else
  clear jin jout jopt
  jin.source = in.group.avg_func;
  jin.mask = in.group.mask_func_group;
  jout = [opt.folder_out 'group' filesep 'template_func_invert.png'];
  pipeline = psom_add_job(pipeline,'template_func_inv','zoo_brick_color_invert',jin,jout,jopt);

  % Generate montage
  clear jin jout jopt
  jin.target = in.template.anat;
  jopt.coord = opt.coord;

  jin.source = pipeline.template_func_inv.files_out;
  jout = [opt.folder_out 'group' filesep 'template_func_stereotaxic_raw.png'];
  jopt.colormap = 'gray';
  jopt.colorbar = false;
  jopt.limits = 'adaptative';
  jopt.flag_decoration = false;
  pipeline = psom_add_job(pipeline,'montage_template_func','niak_brick_vol2img',jin,jout,jopt);
end

%% Group outline
% anat
jin.source = file_outline_anat;
jout = [opt.folder_out 'group' filesep 'outline_anat.png'];
jopt.colormap = 'jet';
jopt.limits = [0 1.1];
jopt.flag_decoration = false;
pipeline = psom_add_job(pipeline,'montage_anat_outline','niak_brick_vol2img',jin,jout,jopt);
% func
jin.source = file_outline_func;
jout = [opt.folder_out 'group' filesep 'outline_func.png'];
jopt.colormap = 'jet';
jopt.limits = [0 1.1];
jopt.flag_decoration = false;
pipeline = psom_add_job(pipeline,'montage_func_outline','niak_brick_vol2img',jin,jout,jopt);

%% Merge templte and outline
% anat
clear jin jout jopt
jin.background = pipeline.montage_template_anat.files_out;
jin.overlay = pipeline.montage_anat_outline.files_out;
jout = [opt.folder_out 'group' filesep 'anat_template_outline_stereotaxic.png'];
jopt.transparency = 0.7;
jopt.threshold = 0.9;
pipeline = psom_add_job(pipeline,'overlay_outlline_anat_template','niak_brick_add_overlay',jin,jout,jopt);
% func
jin.background = pipeline.montage_template_func.files_out;
jin.overlay = pipeline.montage_func_outline.files_out;
jout = [opt.folder_out 'group' filesep 'template_stereotaxic.png'];
jopt.transparency = 0.7;
jopt.threshold = 0.9;
pipeline = psom_add_job(pipeline,'overlay_outlline_func_template','niak_brick_add_overlay',jin,jout,jopt);

%% Panel on individual registration
% Individual T1 images
clear jin jout jopt
jin.target = in.template.anat;
jopt.coord = opt.coord;
jopt.colormap = 'gray';
jopt.limits = 'adaptative';
jopt.method = 'linear';
for ss = 1:length(list_subject)
    jin.source = in.ind.anat.(list_subject{ss});
    jout = [opt.folder_out 'registration' filesep list_subject{ss} '_anat_raw.png'];
    jopt.flag_decoration = false;
    pipeline = psom_add_job(pipeline,['t1_' list_subject{ss}],'niak_brick_vol2img',jin,jout,jopt);
end
% Individual BOLD images
for ss = 1:length(list_subject)
    jin.source = in.ind.func.(list_subject{ss});
    jout = [opt.folder_out 'registration' filesep list_subject{ss} '_func_raw.png'];
    jopt.flag_decoration = false;
    pipeline = psom_add_job(pipeline,['bold_' list_subject{ss}],'niak_brick_vol2img',jin,jout,jopt);
end

% Merge individual T1 and outline
for ss = 1:length(list_subject)
    clear jin jout jopt
    jin.background = pipeline.(['t1_' list_subject{ss}]).files_out;
    jin.overlay = pipeline.overlay_outlline_anat_template.files_out;
    jout = [opt.folder_out 'registration' filesep list_subject{ss} '_anat.png'];
    jopt.transparency = 0.7;
    jopt.threshold = 0.9;
    pipeline = psom_add_job(pipeline,['t1_' list_subject{ss} '_overlay'],'niak_brick_add_overlay',jin,jout,jopt);
end
% Merge individual funt and outline
for ss = 1:length(list_subject)
    clear jin jout jopt
    jin.background = pipeline.(['bold_' list_subject{ss}]).files_out;
    jin.overlay = pipeline.overlay_outlline_func_template.files_out;
    jout = [opt.folder_out 'registration' filesep list_subject{ss} '_func.png'];
    jopt.transparency = 0.7;
    jopt.threshold = 0.9;
    pipeline = psom_add_job(pipeline,['bold_' list_subject{ss} '_overlay'],'niak_brick_add_overlay',jin,jout,jopt);
end

% Add a spreadsheet to write the QC.
clear jin jout jopt
jout = [opt.folder_out 'qc_registration.csv'];
jopt.list_subject = list_subject;
pipeline = psom_add_job(pipeline,'init_report','niak_brick_init_qc_report','',jout,jopt);

% Manifest file for anat workflow
clear jin jout jopt
jout = [opt.folder_out 'anat_manifest_file.csv'];
jopt.list_subject = list_subject;
jopt.modality ='anat'
pipeline = psom_add_job(pipeline,'anat_manifest','zoo_brick_manifest','',jout,jopt);

% Manifest file for func workflow
clear jin jout jopt
jout = [opt.folder_out 'func_manifest_file.csv'];
jopt.list_subject = list_subject;
jopt.modality ='func'
pipeline = psom_add_job(pipeline,'func_manifest','zoo_brick_manifest','',jout,jopt);

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end
