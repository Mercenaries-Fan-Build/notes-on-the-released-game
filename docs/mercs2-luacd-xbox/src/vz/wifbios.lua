local L0_1, L1_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = 0
  L1_2 = pairs
  L2_2 = _tActiveBios
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    L0_2 = L0_2 + 1
  end
  L1_2 = 0 < L0_2
  return L1_2
end

HasBio = L0_1

function L0_1()
  local L0_2, L1_2
  L0_2 = _tActiveBios
  return L0_2
end

SaveSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if not A0_2 then
    return
  end
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L1_2 = not L1_2
  if L1_2 == "table" then
    return
  end
  L1_2 = pairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2 = L1_2(L2_2)
  for L4_2, L5_2 in L1_2, L2_2, L3_2 do
    if L5_2 == true then
      L6_2 = AddDossierEntry
      L7_2 = L4_2
      L6_2(L7_2)
    end
  end
end

LoadSingleton = L0_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = _tBios
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = _tActiveBios
    L2_2[A0_2] = true
    L2_2 = Pda
    L2_2 = L2_2.Database
    L3_2 = L2_2
    L2_2 = L2_2.AddDossierEntry
    L4_2 = {}
    L5_2 = L1_2.sTitle
    L4_2.sTitle = L5_2
    L5_2 = L1_2.sText
    L4_2.sText = L5_2
    L5_2 = L1_2.sIcon
    L4_2.sIcon = L5_2
    L2_2(L3_2, L4_2)
  end
end

AddDossierEntry = L0_1
L0_1 = {}
_tActiveBios = L0_1
L0_1 = 0
_nNum = L0_1
L0_1 = {}
L1_1 = {}
L1_1.sTitle = "[PDA.Database.DOSSIERS]"
L1_1.sText = "[PDA.Database.Dossiers_Description]"
L1_1.sIcon = "icon_people"
L0_1.Default = L1_1
L1_1 = {}
L1_1.sTitle = "[SHELL.SelectCharacter.ChrisJacobs]"
L1_1.sText = "[SHELL.SelectCharacter.ChrisJacobsText]"
L1_1.sIcon = "icon_people"
L0_1.BioChris = L1_1
L1_1 = {}
L1_1.sTitle = "[SHELL.SelectCharacter.JenniferMui]"
L1_1.sText = "[SHELL.SelectCharacter.JenniferMuiText]"
L1_1.sIcon = "icon_people"
L0_1.BioJennifer = L1_1
L1_1 = {}
L1_1.sTitle = "[SHELL.SelectCharacter.MattiasNilsson]"
L1_1.sText = "[SHELL.SelectCharacter.MattiasNilssonText]"
L1_1.sIcon = "icon_people"
L0_1.BioMattias = L1_1
L1_1 = {}
L1_1.sTitle = "[SG0.Name]"
L1_1.sText = "[SHELL.Bio.Acosta]"
L1_1.sIcon = "icon_people"
L0_1.BioAcosta = L1_1
L1_1 = {}
L1_1.sTitle = "[Faction.ALL]"
L1_1.sText = "[SHELL.Bio.Allies]"
L1_1.sIcon = "icon_people"
L0_1.BioAllies = L1_1
L1_1 = {}
L1_1.sTitle = "[SHELL.Bio.Name.Blanco]"
L1_1.sText = "[SHELL.Bio.Blanco]"
L1_1.sIcon = "icon_people"
L0_1.BioBlanco = L1_1
L1_1 = {}
L1_1.sTitle = "[human.vz.carmona]"
L1_1.sText = "[SHELL.Bio.Carmona]"
L1_1.sIcon = "icon_people"
L0_1.BioCarmona = L1_1
L1_1 = {}
L1_1.sTitle = "[Faction.CHI]"
L1_1.sText = "[SHELL.Bio.China]"
L1_1.sIcon = "icon_people"
L0_1.BioChina = L1_1
L1_1 = {}
L1_1.sTitle = "[SP1.Name]"
L1_1.sText = "[SHELL.Bio.Devilbwoy]"
L1_1.sIcon = "icon_people"
L0_1.BioDevilbwoy = L1_1
L1_1 = {}
L1_1.sTitle = "[human.pmc.eva]"
L1_1.sText = "[SHELL.Bio.Eva]"
L1_1.sIcon = "icon_people"
L0_1.BioEva = L1_1
L1_1 = {}
L1_1.sTitle = "[CinematicText.Ewan01]"
L1_1.sText = "[SHELL.Bio.Ewan]"
L1_1.sIcon = "icon_people"
L0_1.BioEwan = L1_1
L1_1 = {}
L1_1.sTitle = "[human.pmc.fiona]"
L1_1.sText = "[SHELL.Bio.Fiona]"
L1_1.sIcon = "icon_people"
L0_1.BioFiona = L1_1
L1_1 = {}
L1_1.sTitle = "[SA0.Name]"
L1_1.sText = "[SHELL.Bio.Joyce]"
L1_1.sIcon = "icon_people"
L0_1.BioJoyce = L1_1
L1_1 = {}
L1_1.sTitle = "[human.pmc.misha]"
L1_1.sText = "[SHELL.Bio.Misha]"
L1_1.sIcon = "icon_people"
L0_1.BioMisha = L1_1
L1_1 = {}
L1_1.sTitle = "[SC0.Name]"
L1_1.sText = "[SHELL.Bio.Peng]"
L1_1.sIcon = "icon_people"
L0_1.BioPeng = L1_1
L1_1 = {}
L1_1.sTitle = "[Faction.PIR]"
L1_1.sText = "[SHELL.Bio.Pirates]"
L1_1.sIcon = "icon_people"
L0_1.BioPirates = L1_1
L1_1 = {}
L1_1.sTitle = "[Generic.Factions.Gur.Long]"
L1_1.sText = "[SHELL.Bio.PLAV]"
L1_1.sIcon = "icon_people"
L0_1.BioPLAV = L1_1
L1_1 = {}
L1_1.sTitle = "[SO0.Name]"
L1_1.sText = "[SHELL.Bio.Rubin]"
L1_1.sIcon = "icon_people"
L0_1.BioRubin = L1_1
L1_1 = {}
L1_1.sTitle = "[human.vz.solano]"
L1_1.sText = "[SHELL.Bio.Solano]"
L1_1.sIcon = "icon_people"
L0_1.BioSolano = L1_1
L1_1 = {}
L1_1.sTitle = "[Faction.OIL]"
L1_1.sText = "[SHELL.Bio.UP]"
L1_1.sIcon = "icon_people"
L0_1.BioUP = L1_1
_tBios = L0_1
L0_1 = "Default"
_sCurrentBio = L0_1
