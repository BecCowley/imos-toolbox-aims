function metadataStr = setAIMSmetadata(site,metadataField)

%This function allows a generic config file to be used with the
%IMOS toolbox for processing AIMS data.
%The function call [mat setAIMSmetadata('[ddb Site]','naming_authority')]
%in global_attributes.txt calls this function with the site and the
%datafield as arguements. This function then passes back an appropriate
%string for that site and field.

%If the site is not reconised, default "IMOS" strings are returned.

%%
% Site Names
% NRS : National Reference Stations eg
%   NRSDAR : Darwin
%   NRSYON : Yongala
%   NRSNIN : Ningaloo
% ITF : Indonesian Through Flow (shallow) mooring array
% PIL : Pilbara mooring array
% KIM : Kimberley mooring array
% NIN : Ningaloo Reef Tantabiddi moorings
% SCR : RV Falkor cruise FK150410 (AIMS 6204) at Scott Reef and surrounds
%

%%
switch metadataField
    % project
    case 'project'
        if identifySite(site,{'SCR'})
            metadataStr = 'Timor Sea Reef Connections';
        else
            metadataStr = 'Integrated Marine Observing System (IMOS)';
        end
        return
        
        % institution
    case 'institution'
        if identifySite(site,{'NRS'})
            metadataStr = 'ANMN-NRS';
        elseif identifySite(site,{'SCR'})
            metadataStr = 'AIMS';
        else
            metadataStr = 'ANMN-QLD';
        end
        return
        
        % abstract
    case 'abstract'
        if identifySite(site,{'SCR'})
            metadataStr = ['About halfway between Northwestern Australia ',...
                'and Indonesia lie some of the planet�s most remote and ',...
                'healthy coral reefs, with biodiversity in places rivaling ',...
                'that of the much better known Great Barrier Reef. Yet the ',...
                'physical connections between these reefs, the factors ',...
                'responsible for their health, and the conditions most ',...
                'likely to threaten them are not fully understood. In April 2015, ',...
                'the RV Falkor steamed to the region for a collaborative ',...
                'project aimed at exploring these connections. The work ',...
                'includes expanding on previous research at shallower reefs, ',...
                'as well as the first ever exploration of some deeper sites.'];
        else
            metadataStr = ['The Queensland and Northern Australia mooring ',...
                'sub-facility is based at the Australian Institute for Marine ',...
                'Science in Townsville.  The sub-facility is responsible for ',...
                'moorings in two geographic regions: Queensland Great Barrier ',...
                'Reef, where four pairs of regional moorings and one National ',...
                'Reference Station are maintained; and Northern Australia, ',...
                'where a National Reference Station and transect of the Timor ',...
                'Sea comprising four regional moorings, are maintained.'];
        end
        return
        
        % references
    case 'references'
        if identifySite(site,{'SCR'})
            metadataStr = 'http://data.aims.gov.au/, http://www.schmidtocean.org/story/show/3493';
        else
            metadataStr = 'http://imos.org.au, http://www.aims.gov.au/imosmoorings/';
        end
        return
        
        % principal_investigator
    case 'principal_investigator'
        if identifySite(site,{'GBR','NRSYON'})
            metadataStr = 'AIMS, Q-IMOS';
        elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN'})
            metadataStr = 'AIMS, WAIMOS';
        elseif identifySite(site,{'NRSDAR'})
            metadataStr = 'IMOS';
        elseif identifySite(site,{'SCR'})
            metadataStr = 'AIMS, UWA';
        else
            metadataStr = 'AIMS';
        end
        return
        
        % principal_investigator_email
    case 'principal_investigator_email'
        if identifySite(site,{'GBR','NRSYON'})
            metadataStr = 'c.steinberg@aims.gov.au';
        elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN'})
            metadataStr = 'c.steinberg@aims.gov.au';
        elseif identifySite(site,{'NRSDAR'})
            metadataStr = 'c.steinberg@aims.gov.au';
        elseif identifySite(site,{'SCR'})
            metadataStr = 'adc@aims.gov.au, greg.ivey@uwa.edu.au';
        else
            %metadataStr = 'info@emii.org.au';
            metadataStr = 'adc@aims.gov.au';
        end
        return
        
        % institution_references
    case 'institution_references'
        if identifySite(site,{'SCR'})
            metadataStr = 'http://data.aims.gov.au, http://www.schmidtocean.org, http://www.imos.org.au/emii.html';
        else
            metadataStr = 'http://www.aims.gov.au/imosmoorings/, http://www.imos.org.au/emii.html';
        end
        return
        
        % acknowledgement, imosToolbox from v2.5 onwards
    case 'acknowledgement'
        defaultStr = ['Any users of IMOS data are required to clearly acknowledge the source ',...
				'of the material derived from IMOS in the format: "Data was sourced from the ',...
				'Integrated Marine Observing System (IMOS) - IMOS is a national collaborative ',...
				'research infrastructure, supported by the Australian Government." If relevant, ',...
				'also credit other organisations involved in collection of this particular datastream ',...
				'(as listed in ''credit'' in the metadata record).'];
        if identifySite(site,{'GBR','NRSYON'})
            metadataStr = [defaultStr,...
                ' The support of the Department of Employment Economic ',...
                'Development and Innovation of the Queensland State ',...
                'Government is also acknowledged. The support of the ',...
                'Tropical Marine Network (University of Sydney, Australian ',...
                'Museum, University of Queensland and James Cook University) ',...
                'on the GBR is also acknowledged".'];
        elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN'})
            metadataStr = [defaultStr,...
                ' The support of the Western Australian State Government is also acknowledged."'];
        elseif identifySite(site,{'NRSDAR'})
            metadataStr = [defaultStr,...
                ' The support of the Darwin Port Corporation is also acknowledged."'];
        elseif identifySite(site,{'SCR'})
            metadataStr = ['Any users of AIMS data are required to clearly acknowledge the source of the ',...
				'material in this format: "Data was sourced from the ',...
                'Australian Institute of Marine Science (AIMS). ',...
				'The support of the University of Western Australia (UWA), the ',...
                'Australian Research Council and the Schmidt ',...
                'Ocean Institute (SOI) is also acknowledged.'];
        else
            metadataStr = defaultStr;
        end
        return
        
        % project_acknowledgement, imosToolbox to v2.4
    case 'project_acknowledgement'
        if identifySite(site,{'GBR','NRSYON'})
            metadataStr = ['The collection of this data was funded by IMOS ',...
                'and delivered through the Queensland and Northern Australia ',...
                'Mooring sub-facility of the Australian National Mooring Network ',...
                'operated by the Australian Institute of Marine Science. ',...
                'IMOS is supported by the Australian Government through the ',...
                'National Collaborative Research Infrastructure Strategy, ',...
                'the Super Science Initiative and the Department of Employment, ',...
                'Economic Development and Innovation of the Queensland State ',...
                'Government. The support of the Tropical Marine Network ',...
                '(University of Sydney, Australian Museum, University of ',...
                'Queensland and James Cook University) on the GBR is also ',...
                'acknowledged.'];
        elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN'})
            metadataStr = ['The collection of this data was funded by IMOS ',...
                'and delivered through the Queensland and Northern Australia ',...
                'Mooring sub-facility of the Australian National Mooring Network ',...
                'operated by the Australian Institute of Marine Science. ',...
                'IMOS is supported by the Australian Government through the ',...
                'National Collaborative Research Infrastructure Strategy, ',...
                'the Super Science Initiative and the Western Australian State Government. '];
        elseif identifySite(site,{'NRSDAR'})
            metadataStr = ['The collection of this data was funded by IMOS',...
                'and delivered through the Queensland and Northern Australia',...
                'Mooring sub-facility of the Australian National Mooring Network',...
                'operated by the Australian Institute of Marine Science.',...
                'IMOS is supported by the Australian Government through the',...
                'National Collaborative Research Infrastructure Strategy,',...
                'and the Super Science Initiative. The support of the Darwin ',...
                'Port Corporation is also acknowledged'];
        else
            metadataStr = ['The collection of this data was funded by IMOS ',...
                'and delivered through the Queensland and Northern Australia ',...
                'Mooring sub-facility of the Australian National Mooring Network ',...
                'operated by the Australian Institute of Marine Science. ',...
                'IMOS is supported by the Australian Government through the ',...
                'National Collaborative Research Infrastructure Strategy, ',...
                'and the Super Science Initiative.'];
        end
        return
        
        % local_time_zone
    case 'local_time_zone'
        if identifySite(site,{'GBR','NRSYON'})
            metadataStr = '+10';
        elseif identifySite(site,{'ITF','NRSDAR'})
            metadataStr = '+9.5';
        elseif identifySite(site,{'PIL', 'KIM', 'NIN'})
            metadataStr = '+8';
        elseif identifySite(site,{'SCR'})
            metadataStr = '+8';
        else
            metadataStr = '+10';
        end
        return
        
end
end

function result = identifySite(site,token)
f = regexp(site,token);
g = cell2mat(f);
result = ~isempty(g);
end