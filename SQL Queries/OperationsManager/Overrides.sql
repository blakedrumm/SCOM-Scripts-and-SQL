	Select WorkflowType, WorkflowName, Overview.OverrideName, OverrideableParameterName, OverrideValue, OverrideDescription, OverrideEnforced, OverrideScope, TargetedInstanceName, TargetedInstancePath, ORMPName, ORMPDescription, ORMPSealed, MPTargetClass, TargetManagementPack, ModuleOverrideId, ORMPLanguage, OverrideLastModified, OverrideCreatedOn  from (
	SELECT 'Rule'          AS 'WorkflowType',
		   rv.displayname  AS WorkflowName,
		   OverrideName,
		   op.OverrideableParameterName,
		   mo.value        AS OverrideValue,
		   lt.ltvalue      AS OverrideDescription,
		   mo.enforced     AS OverrideEnforced,
		   mt.typename     AS OverrideScope,
		   bme.displayname AS TargetedInstanceName,
		   bme.path        AS TargetedInstancePath,
		   mpv.displayname AS ORMPName,
		   mpv.description AS ORMPDescription,
		   mpv.sealed      AS ORMPSealed,
		   mpv.LanguageCode AS ORMPLanguage,
		   mo.lastmodified AS OverrideLastModified,
		   mo.timeadded    AS OverrideCreatedOn
	--op.TimeAdded AS MPTimeCreated
	FROM moduleoverride mo WITH (NOLOCK)
	INNER JOIN managementpackview mpv WITH (NOLOCK)
	ON mpv.id = mo.managementpackid
	INNER JOIN ruleview rv WITH (NOLOCK)
	ON rv.id = mo.parentid
	INNER JOIN managedtype mt WITH (NOLOCK)
	ON mt.managedtypeid = mo.typecontext
	LEFT JOIN localizedtext lt WITH (NOLOCK)
	ON lt.ltstringid = mo.moduleoverrideid
	LEFT JOIN basemanagedentity bme WITH (NOLOCK)
	ON bme.basemanagedentityid = mo.instancecontext
	LEFT JOIN overrideableparameter op WITH (NOLOCK)
	ON mo.overrideableparameterid = op.overrideableparameterid
	--Where (lt.LTStringType = 2 and mpv.LanguageCode = 'ENU')
	--Where (mpv.Sealed = 0 and mpv.LanguageCode = 'ENU')
	--Where mpv.Sealed = 0
	UNION ALL
	SELECT 'Monitor'        AS 'WorkflowType',
		   mv.displayname   AS WorkflowName,
		   OverrideName,
		   op.OverrideableParameterName,
		   mto.value        AS OverrideValue,
		   lt.ltvalue       AS OverrideDescription,
		   mto.enforced     AS OverrideEnforced,
		   mt.typename      AS OverrideScope,
		   bme.displayname  AS TargetedInstanceName,
		   bme.path         AS TargetedInstancePath,
		   mpv.displayname  AS ORMPName,
		   mpv.description  AS ORMPDescription,
		   mpv.sealed       AS ORMPSealed,
		   mpv.LanguageCode AS ORMPLanguage,
		   mto.lastmodified AS OverrideLastModified,
		   mto.timeadded    AS OverrideCreatedOn
	--mpv.TimeCreated AS MPTimeCreated
	FROM monitoroverride mto WITH (NOLOCK)
	INNER JOIN managementpackview mpv WITH (NOLOCK)
	ON mpv.id = mto.managementpackid
	INNER JOIN monitorview mv WITH (NOLOCK)
	ON mv.id = mto.monitorid
	INNER JOIN managedtype mt WITH (NOLOCK)
	ON mt.managedtypeid = mto.typecontext
	LEFT JOIN localizedtext lt WITH (NOLOCK)
	ON lt.ltstringid = mto.monitoroverrideid
	LEFT JOIN basemanagedentity bme WITH (NOLOCK)
	ON bme.basemanagedentityid = mto.instancecontext
	LEFT JOIN overrideableparameter op WITH (NOLOCK)
	ON mto.overrideableparameterid = op.overrideableparameterid
	--Where (lt.LTStringType = 2 and mpv.LanguageCode = 'ENU')
	--Where (mpv.Sealed = 0 and mpv.LanguageCode = 'ENU')
	--Where mpv.Sealed = 0
	UNION ALL
	SELECT 'Discovery'     AS 'WorkflowType',
		   dv.displayname  AS WorkflowName,
		   OverrideName,
		   op.OverrideableParameterName,
		   mo.value        AS OverrideValue,
		   lt.ltvalue      AS OverrideDescription,
		   mo.enforced     AS OverrideEnforced,
		   mt.typename     AS OverrideScope,
		   bme.displayname AS TargetedInstanceName,
		   bme.path        AS TargetedInstancePath,
		   mpv.displayname AS ORMPName,
		   mpv.description AS ORMPDescription,
		   mpv.sealed      AS ORMPSealed,
		   mpv.LanguageCode AS ORMPLanguage,
		   mo.lastmodified AS OverrideLastModified,
		   mo.timeadded    AS OverrideCreatedOn
	--mpv.TimeCreated AS MPTimeCreated
	FROM moduleoverride mo WITH (NOLOCK)
	INNER JOIN managementpackview mpv WITH (NOLOCK)
	ON mpv.id = mo.managementpackid
	INNER JOIN discoveryview dv WITH (NOLOCK)
	ON dv.id = mo.parentid
	INNER JOIN managedtype mt WITH (NOLOCK)
	ON mt.managedtypeid = mo.typecontext
	LEFT JOIN localizedtext lt WITH (NOLOCK)
	ON lt.ltstringid = mo.moduleoverrideid
	LEFT JOIN basemanagedentity bme WITH (NOLOCK)
	ON bme.basemanagedentityid = mo.instancecontext
	LEFT JOIN overrideableparameter op WITH (NOLOCK)
	ON mo.overrideableparameterid = op.overrideableparameterid
	--Where (lt.LTStringType = 2 and mpv.LanguageCode = 'ENU')
	--Where (mpv.Sealed = 0 and mpv.LanguageCode = 'ENU')
	)Overview
	

LEFT JOIN (
	SELECT mo.ModuleOverrideId, mo.OverrideName, mpv.DisplayName as 'MPTargetClass', mpv.FriendlyName as [TargetManagementPack] FROM ModuleOverride mo WITH (NOLOCK)
	INNER JOIN Managedtype mt WITH (NOLOCK) on mt.ManagedTypeId = mo.TypeContext
	INNER JOIN ManagementPackView mpv on mpv.ID = mt.ManagementPackId
	Where mpv.LanguageCode = 'ENU'
) OverridesOverview ON OverridesOverview.OverrideName = Overview.OverrideName

ORDER BY OverrideLastModified DESC