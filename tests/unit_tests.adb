with Generic_Collection_Test;
with Generic_Table_Test;
with Remote_Node_Test;

package body Unit_Tests is

   function Suite return Access_Test_Suite is

      type T_GenericTableTest is access all Generic_Table_Test.Test'Class;
      type T_GenericCollectionTest is access all Generic_Collection_Test.Test'Class;
      type T_RemoteNodeTest is access all Remote_Node_Test.Test'Class;

      Ret : constant Access_Test_Suite := new Test_Suite;

      GenericTableTest : constant T_GenericTableTest := new Generic_Table_Test.Test;

      GenericCollectionTest : constant T_GenericCollectionTest := new Generic_Collection_Test.Test;

      RemoteNodeTest : constant T_RemoteNodeTest := new Remote_Node_Test.Test;

   begin
      Ret.Add_Test (GenericTableTest);
      Ret.Add_Test (GenericCollectionTest);
      Ret.Add_Test (RemoteNodeTest);
      return Ret;
   end Suite;

end Unit_Tests;
