with Ada.Exceptions;                     use Ada.Exceptions;

package body Client_Manager is

   task body Client_Task is

      procedure Destroy is
      begin
         null;
      end Destroy;

      Me : Client_Type;
      Packet : Unbounded_String;
      Current_Figure_Id : Natural := 1;

   begin
      --Put_Line("Initated.");
      accept Set(Self: Client_Type) do
         Me := Self;
      end Set;

      accept Run ;

      --Put_Line("Started: " & To_String(Me.Nick));
      if Login(Me.Socket) then
         Me.Nick := Get_Nick(Me.Socket);
         Logger.Put("Nick set to: "& To_String(Me.Nick));
         Send_Parts(Me.Socket);
         Logger.Put("Parts sent to "& To_String(Me.Nick));

         while Figures.Exist(Current_Figure_Id) Loop
            Send_Figure(Me.Socket, Current_Figure_Id);
            Logger.Put("Figure #"& To_String(Current_Figure_Id) &" sent to "& To_String(Me.Nick));
            Packet := Get_Line(Me.Socket);
            case Packet_Head(Packet) is
               when Packets.ROTATION_HEAD =>
                  if Verify(Get_Dec(Parts.Get,Packet_Content(Packet)),
                            Figures.Get(Current_Figure_Id)) then
                     Result_List.Insert(Me.Results,
                                        New_Result(Current_Figure_Id,
                                                   True,
                                                   To_Unbounded_String("Passed")));
                     Send_Result(Me.Socket, "Passed");
                     Logger.Put("Client "& To_String(Me.Nick) &" sent result for figure #"
                                  & To_String(Current_Figure_Id) &", Passed"
                                  &", "& To_String(Packet_Content(Packet)));
                  else
                     Result_List.Insert(Me.Results,
                                        New_Result(Current_Figure_Id,
                                                   False,
                                                   To_Unbounded_String("Failed")));
                     Send_Result(Me.Socket, "Failed");
                     Logger.Put("Client "& To_String(Me.Nick) &" sent result for figure #"
                                  & To_String(Current_Figure_Id) &", Failed"
                                  &", "& To_String(Packet_Content(Packet)));
                  end if;
                  Current_Figure_Id := Current_Figure_Id + 1;
               when Packets.FORFEIT_HEAD =>
                  Result_List.Insert(Me.Results,
                                     New_Result(Current_Figure_Id,
                                                False,
                                                To_Unbounded_String("Ignored")));
                  Send_Result(Me.Socket, "Ignored");
                  Logger.Put("Client "& To_String(Me.Nick) &" sent result for figure #"
                               & To_String(Current_Figure_Id) &", Ignored"
                               &", "& To_String(Packet_Content(Packet)));
                  Current_Figure_Id := Current_Figure_Id + 1;
               when Packets.FINISH_HEAD =>
                  Send_Finish(Me.Socket, Result_List.Length(Me.Results), 1);
                  Logger.Put("Client "& To_String(Me.Nick) &" disconnected.");
                  delay 5.0;
                  Close(Me.Socket);
                  exit;
               when others =>
                  Put_Line(Me.Socket, "ERROR: Command out of order. Bye...");
                  Logger.Put("Client "& To_String(Me.Nick) &" ERROR: "& To_String(Packet));
                  delay 5.0;
                  Close(Me.Socket);
                  exit;
            end case;
         end loop;
         Send_Finish(Me.Socket, Result_List.Length(Me.Results), 1);
         Logger.Put("Client "& To_String(Me.Nick) &" disconnected.");
         delay 5.0;
         Close(Me.Socket);
      else
         Close(Me.Socket);
         Logger.Put("Login error.");
      end if;
   exception
      when others =>
         --Put("An error has occured.");
         Put_Line(Me.Socket, "ERROR: An error has occured. Bye...");
         delay 5.0;
         Close(Me.Socket);
   end Client_Task;

   protected body Logger is
      procedure Init is
      begin
         begin
            Open(Log, Append_File, "log.log");
         exception
            when Ada.Text_IO.Name_Error =>
               Create(Log, Out_File, "log.log");
         end;
      end Init;

      procedure Put(Event: String) is
      begin
         Init;
         Put(Log, To_String(Get_Date(Clock)) &" "& To_String(Get_Time(Clock)) &" ");
         Put_Line(Log, Event);
         Close(Log);
      end Put;

      procedure Put(Event: Unbounded_String) is
      begin
         Put(To_String(Event));
      end Put;
   end Logger;

   protected body Clients is
      procedure Insert(Item: in Client_Type) is
      begin
         Client_List.Insert(List, Item);
      end Insert;

      procedure Remove(Item: in Socket_Type) is
      begin
         Client_List.Remove(List, Item);
      end Remove;

      procedure Put is
      begin
         Client_List.Put(List);
      end Put;
   end Clients;

   protected body Parts is
      function Get return Unbounded_String is
      begin
         return To_Unbounded_String(Parts.all);
      end Get;

      function Get return Part_Array is
      begin
         return Parts.all;
      end Get;

      procedure Set (Parts_In : Part_Array) is
      begin
         Parts := new Part_Array(Parts_In'Range);
         Parts.all := Parts_In;
      end Set;
   end Parts;

   protected body Figures is
      function Get(Id : Natural) return Unbounded_String is
      begin
         return To_Unbounded_String(To_String(Id))
           &" "& To_Unbounded_String(Figures.all(Id));
      end Get;

      function Get(Id : Natural) return Full_Part is
      begin
         return Figures.all(Id);
      end Get;

      function Exist(Id : Natural) return Boolean is
      begin
         return (Figures'First <= Id) and (Figures'Last >= Id);
      end Exist;

      procedure Set (Figures_In : Part_Array) is
      begin
         Figures := new Part_Array(Figures_In'Range);
         Figures.all := Figures_In;
      end Set;
   end Figures;

   function Login (Socket: Socket_Type) return Boolean is
   begin
      if To_Unbounded_String("adap") = Get_Line(Socket) then
         if To_Unbounded_String("bacon") = Get_Line(Socket) then
            Put_Line(Socket, "OK");
            return True;
         end if;
      end if;
      Put_Line(Socket, "REJECTED");
      return False;
   end Login;

   function Get_Nick (Socket: Socket_Type) return Unbounded_String is
      Packet : Unbounded_String;
   begin
      Packet := Get_Line(Socket);
      if Packet_Head(Packet) = Packets.NICK_HEAD then
         return Packet_Content(Packet);
      end if;
      raise Unexpected_Head_Type;
   end Get_Nick;

   procedure Send_Parts(Socket: in Socket_Type) is
   begin
      Put_Line(Socket, Assemble_Packet(Packets.PART_HEAD,Parts.Get));
   end Send_Parts;

   procedure Send_Figure(Socket: in Socket_Type; Figure_Id : Natural) is
   begin
      Put_Line(Socket, Assemble_Packet(Packets.FIGURE_HEAD,Figures.Get(Figure_Id)));
   end Send_Figure;

   function New_Result (Figure_Id: Positive;
                        Solved: Boolean;
                        Result: Unbounded_String) return Result_Type is
     Res : Result_Type;
   begin
      Res.Figure_Id := Figure_Id;
      Res.Solved := Solved;
      Res.Result := Result;
      return Res;
   end New_Result;

   procedure Send_Result(Socket: Socket_Type; Result: String) is
   begin
      Put_Line(Socket, Assemble_Packet(Packets.RESULT_HEAD,
                               To_Unbounded_String(Result)));
   end Send_Result;

   procedure Send_Finish (Socket: Socket_Type; Solved: Natural; Place: Natural) is
   begin
      Put_Line(Socket, Assemble_Packet(Packets.FINISH_HEAD,
                               To_Unbounded_String(To_String(Solved) &" "& To_String(Place))));
   end Send_Finish;

   function Get_New_Client return Client_Type is
   New_Client : Client_Type;
   begin
      New_Client := new Client_Element_Type;
      New_Client.Nick := To_Unbounded_String("");
      New_Client.Self := New_Client;
      New_Client.T.Set(New_Client);
      return New_Client;
   end Get_New_Client;

   function Get_Socket (Item: in Client_Type) return Socket_Type is
   begin
      return Item.Socket;
   end Get_Socket;

   procedure Put (Item: in Client_Type) is
   begin
      Put_Line(To_String(Item.Nick));
      Result_List.Put(Item.Results);
   end Put;

   function Get_Figure_Id (Item: in Result_Type) return Positive is
   begin
      return Item.Figure_Id;
   end Get_Figure_Id;

   procedure Put (Item: in Result_Type) is
   begin
      Put(Item.Figure_Id);
      Put(" ");
      Put(Item.Result);
      New_Line;
   end Put;

end Client_Manager;
