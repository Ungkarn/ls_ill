classdef Sample < dynamicprops
% This class takes as input some info about a sample and stores it.
 properties
  Protein					% what protein?
  Salt						% what salt?
  C						% protein concentration
  Unit_C	= 'g/l';
  Cs						% salt concentration
  Unit_Cs	= 'mM'
  Unit_KcR	= 'mol g^{-1}'
  Unit_X_T	= 'l * J^{-1}';
  T
  Unit_T	= 'K';
  n
  dndc
  Point						% datapoints
 end
 properties ( SetAccess = private, Dependent )
  Angle
  Q
  KcR 
  dKcR
  X_T
  dX_T
 end
 properties ( Hidden)
  Instrument
  C_set
  n_set
  dndc_set
  raw_data_path
  date_experiment
  RawData
  KcR_corr
 end
 methods
  function self = Sample( varargin )
   a	= Args(varargin{:})	;							% get the args
   try		self.Instrument	= Instruments.(a.Instrument);				% get the instrument
   catch 	error('Instrument not found!');
   end
   props	= {	'Protein',	'Salt',		...
			'C',		'C_set',	...
			'Cs',		'T',		...
			'n',		'n_set',	...
			'dndc',		'dndc_set'	};
   for i = 1 : length(props)
    try		self.(props{i})		= a.(props{i});
    catch	warning(['Property ' props{i} ' not found!']);
    end
   end
if any(strcmp('filegroup_index', properties(a)))
	filegroup_index = a.filegroup_index;
else
	filegroup_index = 1;
end
 if any(strcmp('path_standard', properties(a)))
	   bool_get_data_from_autosave = 1;
else
	   bool_get_data_from_autosave = 0;
	end
	% get data from table
	if ~bool_get_data_from_autosave
	   try		self.Point	= self.Instrument.read_static_file ( a.Path );  	% get the KcR and angles
	   catch disp(a.Path)
	       error('Error loading the static file!');
	   end
    else
		[s_array, e_array, nc_array] = self.Instrument.find_start_end( a.Path );
		start_index = s_array(filegroup_index);
		end_index = e_array(filegroup_index);
		nc = nc_array(filegroup_index);

		disp(['Load SLS:' a.Path '[' num2str(start_index,'%4.4u') ':' num2str(end_index,'%4.4u') ']' ])

		path_standard = a.path_standard;
		path_solvent  = a.path_solvent;
		[self.Point self.RawData] = self.Instrument.read_static(path_standard, path_solvent, ...
			a.Path, self.C, self.dndc, start_index, end_index, nc);
	end
   self.raw_data_path = a.Path;
   pointprops	= {	'Protein',	'Salt',		...
			'C',		'C_set',	...
			'Cs',				...
			'n',		'n_set',	...
			'dndc',		'dndc_set'	};
   for i = 1 : length(pointprops)
     [ self.Point.(pointprops{i}) ]	= deal(a.(pointprops{i}));			% the deal function rocks!
   end
  end
  function [KcR_corr] = get.KcR_corr( self )
	  if isfield(self.RawData, 'SlsData' )
		sls_data = self.RawData.SlsData;
		for i_angle = 1 : length(sls_data)
			for i_att = 1 : length(self.Instrument.attenuator)
				if ( round(sls_data(i_angle).count(1).monitor_intensity / self.Instrument.attenuator(i_att).monitor_intensity) == 1)
					correction_factor = self.Instrument.attenuator(i_att).intensity_correction;
					% disp(['angle=' num2str(sls_data(i_angle).scatt_angle)...
					% 	', Att=' num2str(i_att) ...
					% 	', corr=' num2str(correction_factor) ...
					% 	', trans=' num2str(self.Instrument.attenuator(i_att).percent_transmission)]);
					KcR_corr(i_angle) = sls_data(i_angle).KcR * correction_factor;
					% disp(self.Point(i_angle).KcR_raw);
					dKcR_corr(i_angle) = sls_data(i_angle).dKcR* correction_factor;
					break
				end
			end
		end
	  else
		  disp('no raw data from autosave available ! -> exit')
	  end
  end
  function KcR	= get.KcR ( self )
   y	= [ self.Point.KcR ];
   w	= 1./ [ self.Point.dKcR ].^2;
   KcR	= sum( y .* w ) / sum( w );
  end 
  function dKcR	= get.dKcR ( self )
   y	= [ self.Point.dKcR ];
   w	= 1./ [ self.Point.dKcR ].^2;
   dKcR	= sum( y .* w ) / sum( w );
  end
  function X_T	= get.X_T ( self )
   y	= [ self.Point.X_T ];
   w	= 1./ [ self.Point.dX_T ].^2;
   X_T	= sum( y .* w ) / sum( w );   
  end
  function dX_T	= get.dX_T ( self )
   y	= [ self.Point.dX_T ];
   w	= 1./ [ self.Point.dX_T ].^2;
   dX_T	= sum( y .* w ) / sum( w );   
  end
  function Angle= get.Angle ( self )
   Angle= unique([self.Point.Angle]);
  end
  function Q	= get.Q ( self )
   Q	= unique([self.Point.Q]);
  end
 end
 methods(Access = private, Static)
	 [s e nc] = find_start_end( path )
 end
end
