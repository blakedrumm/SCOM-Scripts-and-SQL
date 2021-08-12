select
mpv.Id,
mpv.DisplayName,
mpv.Name,
mpv.FriendlyName,
mpv.Version,
mpv.Sealed,
mpv.LastModified,
mpv.TimeCreated,
mpv.Description,
mpv.LanguageCode AS 'Language'
--CAST(mp.MPXML AS xml) AS 'XML'
from ManagementPackView mpv
inner join ManagementPack mp
on mpv.id = mp.ManagementPackId