{ This file was automatically created by Lazarus. do not edit ! 
  This source is only used to compile and install the package.
 }

unit linesip_buttons; 

interface

uses
  untButtonList, LazarusPackageIntf;

implementation

procedure Register; 
begin
  RegisterUnit ( 'untButtonList', @untButtonList.Register ) ; 
end; 

initialization
  RegisterPackage ( 'linesip_buttons', @Register ) ; 
end.
