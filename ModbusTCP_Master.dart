import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:convert' show utf8;
import 'dart:typed_data';
//import 'dart:convert';

enum ModbusTCP_Func{
	None,
	WriteSingleCoil,
	WriteCoils,
	ReadCoils,
	WriteSingleRegister,
	WriteRegisters,
	ReadRegisters,
}

class ModbusTCP_Master
{
	String _IP_Addr; //InternetAddress.loopbackIPv4;//
	int _port;
	Socket _mSocket;
	ModbusTCP_Func _mFuncType=ModbusTCP_Func.None;
	bool _debugEN=false;
	static const int W_cmd_bit=0x05;
	static const int W_cmd_bits=0x0F;
	static const int W_cmd_reg=0x06;
	static const int W_cmd_regs=0x10;
	static const int R_cmd_bits=0x01;
	static const int R_cmd_regs=0x03;
	
	ModbusTCP_Master([this._IP_Addr="127.0.0.1",this._port=502]);
	
	Future<bool> EnableModbusTCP() async
	{
		return Socket.connect(_IP_Addr, _port).then((Socket socket) async
		{
			print('connection OK.');
			_mSocket = socket;
			_mSocket.listen(_readData,
					onError: _errorHandler,
					// onDone: DisableModbusTCP,
					cancelOnError: false);
			return true;
		}).catchError((e) {
			print('connection Exception:$e.');
			//await Future.delayed(const Duration(seconds: 1));
			return false;
			//EnableModbusTCP();
		});
	}
	
	void DisableModbusTCP()
	{
		if(_mSocket != null)
		{
			_mSocket.close();
			_mSocket.destroy();
			print('disconnection OK.');
		}
	}
	
	void _writeData(Uint8List data)
	{
		//print("!!!***实际发送给Server的数据：${data.toList()}");
		_mSocket.add(data);
	}
	
	void _errorHandler(error, StackTrace trace){
		print(error);
	}
	
	bool _bReadFlag=false;
	bool _bInModTCPRead=false;
	Uint8List _read_bytes = Uint8List(32 * 2 + 9); //最多读取32个数据TCP
	int _read_bytes_num = 0;
	void _readData(Uint8List data)
	{
		//print("!!!***接收到来自Server的数据：${data.toList()}");
		if(!(_bInModTCPRead&!_bReadFlag)) {
			return;
		}
		
		_read_bytes = Uint8List(_read_bytes_num+0);
		for (int i = 0; i < _read_bytes_num; i++) {
			_read_bytes[i] = data[i];
		}
		_bReadFlag=true;
	}
	
	void _WriteSingleCoil(int coil_addr, bool coil_value) async
	{
		if(_mSocket == null)  return;
		do {
			await Future.delayed(Duration(milliseconds: 0));
		} while (_mFuncType!=ModbusTCP_Func.None);
		_mFuncType=ModbusTCP_Func.WriteSingleCoil;
		
		Uint8List data_frame = Uint8List(12);
		int value_hi = coil_value ? 0xFF : 0x00 ;
		
		data_frame[0] = 0x00;      //事务处理标识符高位 –由服务器复制 –通常为 0
		data_frame[1] = 0x00;      //事务处理标识符低位 –由服务器复制 –通常为 0
		data_frame[2] = 0x00;      //协议标识符高位= 0
		data_frame[3] = 0x00;      //协议标识符低位= 0
		data_frame[4] = 0x00;      //长度字段高位 = 0
		data_frame[5] = 0x06;        //长度字段低位 = length
		data_frame[6] = 0x00;       //单元标识符，一般可以不设置
		data_frame[7] = W_cmd_bit;         //MODBUS读写功能码
		data_frame[8] = coil_addr >>8;      //起始寄存器地址高位
		data_frame[9] =  coil_addr << 8>>8;     //起始寄存器地址低位
		data_frame[10] =value_hi;
		data_frame[11] =0x00;
		
		if(_debugEN) print("!!!***待写入线圈：${coil_value}");
		_writeData(data_frame);
		_mFuncType=ModbusTCP_Func.None;
	}
	void _WriteCoils(int coil_addr, int coil_num, List<bool> coil_values) async
	{
		if(_mSocket == null)  return;
		do {
			await Future.delayed(Duration(milliseconds: 0));
		} while (_mFuncType!=ModbusTCP_Func.None);
		_mFuncType=ModbusTCP_Func.WriteCoils;
		
		int bytes_num =(coil_num + 7)~/ 8;// 写入多个线圈，一次最多写入16个线圈状态
		int length=13 + bytes_num;
		int value = 0;
		Uint8List data_frame = Uint8List(15);
		
		for (int i = 0; i < coil_values.length; i++){ //将16个位转换为一个字
			value = coil_values[i] ? (value + math.pow(2, i)) : value;
		}
		
		data_frame[0] = 0x00;      //事务处理标识符高位 –由服务器复制 –通常为 0
		data_frame[1] = 0x00;      //事务处理标识符低位 –由服务器复制 –通常为 0
		data_frame[2] = 0x00;      //协议标识符高位= 0
		data_frame[3] = 0x00;      //协议标识符低位= 0
		data_frame[4] = 0x00;      //长度字段高位 = 0
		data_frame[5] = length-6;        //长度字段低位 = length
		data_frame[6] = 0x00;       //单元标识符，一般可以不设置
		data_frame[7] = W_cmd_bits;         //MODBUS读写功能码
		data_frame[8] = coil_addr >>8;      //起始寄存器地址高位
		data_frame[9] =  coil_addr << 8>>8;     //起始寄存器地址低位
		data_frame[10] =coil_num >>8;
		data_frame[11] =coil_num << 8>>8;
		data_frame[12] =bytes_num;
		data_frame[13] =value << 8>>8;
		data_frame[14] =value >>8;
		if(_debugEN) print("!!!***待写入线圈：${coil_values.toList()}");
		_writeData(data_frame);
		_mFuncType=ModbusTCP_Func.None;
	}
	void _WriteSingleRegister(int reg_addr, int reg_value) async
	{
		if(_mSocket == null)  return;
		do {
			await Future.delayed(Duration(milliseconds: 0));
		} while (_mFuncType!=ModbusTCP_Func.None);
		_mFuncType=ModbusTCP_Func.WriteSingleRegister;
		
		Uint8List data_frame = Uint8List(12);
		
		data_frame[0] = 0x00;      //事务处理标识符高位 –由服务器复制 –通常为 0
		data_frame[1] = 0x00;      //事务处理标识符低位 –由服务器复制 –通常为 0
		data_frame[2] = 0x00;      //协议标识符高位= 0
		data_frame[3] = 0x00;      //协议标识符低位= 0
		data_frame[4] = 0x00;      //长度字段高位 = 0
		data_frame[5] = 0x06;        //长度字段低位 = length
		data_frame[6] = 0x00;       //单元标识符，一般可以不设置
		data_frame[7] = W_cmd_reg;         //MODBUS读写功能码
		data_frame[8] = reg_addr >>8;      //起始寄存器地址高位
		data_frame[9] =  reg_addr << 8>>8;     //起始寄存器地址低位
		data_frame[10] =reg_value >>8;
		data_frame[11] =reg_value << 8>>8;
		if(_debugEN) print("!!!***待写入数据：${reg_value}");
		_writeData(data_frame);
		_mFuncType=ModbusTCP_Func.None;
	}
	void _WriteRegisters(int reg_addr, int reg_num, Int16List reg_value) async
	{
		if(_mSocket == null)  return;
		do {
			await Future.delayed(Duration(milliseconds: 0));
		} while (_mFuncType!=ModbusTCP_Func.None);
		_mFuncType=ModbusTCP_Func.WriteRegisters;
		
		int bytes_num = reg_num * 2;
		int length =13 + bytes_num;
		Uint8List data_frame = Uint8List(length);  //List<Int16>
		
		data_frame[0] = 0x00;      //事务处理标识符高位 –由服务器复制 –通常为 0
		data_frame[1] = 0x00;      //事务处理标识符低位 –由服务器复制 –通常为 0
		data_frame[2] = 0x00;      //协议标识符高位= 0
		data_frame[3] = 0x00;      //协议标识符低位= 0
		data_frame[4] = 0x00;      //长度字段高位 = 0
		data_frame[5] = (length - 6);        //长度字段低位 = length
		data_frame[6] = 0x00;       //单元标识符，一般可以不设置
		data_frame[7] = W_cmd_regs;         //MODBUS读写功能码
		data_frame[8] = reg_addr >>8;      //起始寄存器地址高位
		data_frame[9] =  reg_addr << 8>>8;     //起始寄存器地址低位
		data_frame[10] =reg_num >>8;
		data_frame[11] =reg_num << 8>>8;
		data_frame[12] = bytes_num;
		
		if(_debugEN) print("!!!***待写入数据：${reg_value.toList()}");
		for (int i = 0; i < reg_num; i++)
		{
			data_frame[13 + i * 2] =reg_value[i]>>8;
			data_frame[14 + i * 2] =reg_value[i]<<8>>8;
		}
		
		_writeData(data_frame);
		//print("!!!***写入命令发送完成");
		_mFuncType=ModbusTCP_Func.None;
	}
	Future<void> _ReadRegisters(int reg_addr, int reg_num, Int16List reg_value) async
	{
		if(_mSocket == null)  return;
		do {
			await Future.delayed(Duration(milliseconds: 0));
		} while (_mFuncType!=ModbusTCP_Func.None);
		_mFuncType=ModbusTCP_Func.ReadRegisters;
		_bReadFlag=false;
		
		Uint8List data_frame = Uint8List(12);
		
		data_frame[0] = 0x00;      //事务处理标识符高位 –由服务器复制 –通常为 0
		data_frame[1] = 0x00;      //事务处理标识符低位 –由服务器复制 –通常为 0
		data_frame[2] = 0x00;      //协议标识符高位= 0
		data_frame[3] = 0x00;      //协议标识符低位= 0
		data_frame[4] = 0x00;      //长度字段高位 = 0
		data_frame[5] = 0x06;      //长度字段低位 = length
		data_frame[6] = 0x00;       //单元标识符，一般可以不设置
		data_frame[7] = R_cmd_regs;         //MODBUS读写功能码
		data_frame[8] = reg_addr >>8;      //起始寄存器地址高位
		data_frame[9] =  reg_addr << 8>>8;     //起始寄存器地址低位
		data_frame[10] =reg_num >>8;
		data_frame[11] =reg_num << 8>>8;
		_writeData(data_frame);
		
		_bInModTCPRead=true;
		_read_bytes_num = reg_num * 2 + 9;
		do {
			await Future.delayed(Duration(milliseconds: 0));
		} while (!_bReadFlag);
		
		try {
			for (int i = 0; i < _read_bytes[8]; i = i + 2)
			{
				int k=i ~/ 2;
				reg_value[k] =(_read_bytes[9 + i] <<8) + (_read_bytes[10 + i]);
				//print("$k-->${reg_value[k]}-->:${_read_bytes[9 + i] <<8}-->:${_read_bytes[10 + i]}");
			}
		}catch(e){print(e);}
		
		if(_debugEN) print("!!!***已读取数据：${reg_value.toList()}");
		_read_bytes_num = 0;
		_bReadFlag = false;
		_bInModTCPRead=false;
		_mFuncType=ModbusTCP_Func.None;
	}
	Future<void> _ReadCoils(int coil_addr, int coil_num, List<bool> coil_values) async
	{
		if(_mSocket == null)  return;
		do {
			await Future.delayed(Duration(milliseconds: 0));
		} while (_mFuncType!=ModbusTCP_Func.None);
		_mFuncType=ModbusTCP_Func.ReadCoils;
		
		_bReadFlag=false;
		Uint8List data_frame = Uint8List(12); //读取多个线圈，一次最多读取16个线圈状态
		
		data_frame[0] = 0x00;      //事务处理标识符高位 –由服务器复制 –通常为 0
		data_frame[1] = 0x00;      //事务处理标识符低位 –由服务器复制 –通常为 0
		data_frame[2] = 0x00;      //协议标识符高位= 0
		data_frame[3] = 0x00;      //协议标识符低位= 0
		data_frame[4] = 0x00;      //长度字段高位 = 0
		data_frame[5] = 0x06;      //长度字段低位 = length
		data_frame[6] = 0x00;       //单元标识符，一般可以不设置
		data_frame[7] = R_cmd_bits;         //MODBUS读写功能码
		data_frame[8] = coil_addr >>8;      //起始寄存器地址高位
		data_frame[9] =  coil_addr << 8>>8;     //起始寄存器地址低位
		data_frame[10] =coil_num >>8;
		data_frame[11] =coil_num << 8>>8;
		_writeData(data_frame);
		
		_bInModTCPRead=true;
		_read_bytes_num =  (coil_num + 7)~/8 + 9;// ~/符号为取整数的除法，相当于((coil_num + 7)/8).truncate() 操作。
		do {
			await Future.delayed(Duration(milliseconds: 0));
		} while (!_bReadFlag);
		
		try {
			for (int i = 0; i < 8; i++)
			{
				int square = math.pow(2, i);
				coil_values[i] = (_read_bytes[9] & square) == square ? true : false;
				if (coil_num > 8){
					coil_values[8+i] = (_read_bytes[10] & square) == square ? true : false;
				}
			}
		}catch(e){print(e);}
		
		if(_debugEN) print("!!!***已读取线圈：${coil_values.toList()}");
		_read_bytes_num = 0;
		_bReadFlag = false;
		_bInModTCPRead=false;
		_mFuncType=ModbusTCP_Func.None;
	}
	
	///Extended Modbus Functions
	void WriteSingleBit(int coil_addr, bool coil_value)
	{
		return _WriteSingleCoil(coil_addr, coil_value);
	}
	void WriteBits(int coil_addr, int coil_num, List<bool> coil_values)
	{
		return _WriteCoils(coil_addr,coil_num,coil_values);
	}
	Future<bool> ReadSingleBit(int coil_addr) async
	{
		List<bool> coil_buffer=[
			false,false,false,false,false,false,false,false,
			false,false,false,false,false,false,false,false,
		];
		await _ReadCoils(coil_addr, 1, coil_buffer);
		return coil_buffer[0];
	}
	Future<List<bool>> ReadBits(int coil_addr, int coil_num) async
	{
		List<bool> coil_values=[
			false,false,false,false,false,false,false,false,
			false,false,false,false,false,false,false,false,
		];
		await _ReadCoils(coil_addr, coil_num, coil_values);
		return coil_values;
	}
	void WriteSingleRegister_Int16(int reg_addr, int reg_value)
	{
		return _WriteSingleRegister(reg_addr, reg_value);
	}
	void WriteRegisters_Int16(int reg_addr, int reg_num, Int16List reg_value)
	{
		return _WriteRegisters(reg_addr, reg_num, reg_value);
	}
	Future<int> ReadSingleRegister_Int16(int reg_addr) async
	{
		Int16List read_buffer=Int16List(1);
		await _ReadRegisters(reg_addr, 1, read_buffer);
		return read_buffer[0];
	}
	Future<Int16List> ReadRegisters_Int16(int reg_addr, int reg_num) async
	{
		Int16List reg_value=Int16List(16);
		await _ReadRegisters(reg_addr, reg_num, reg_value);
		return reg_value;
	}
	void WriteSingleRegister_Int32(int reg_addr, int reg_value)
	{
		Int32List temp =Int32List(1);
		temp[0] = reg_value;
		Int16List temp_short = Int16List.view(temp.buffer);
		_WriteRegisters(reg_addr, 2, temp_short);
	}
	void WriteRegisters_Int32(int reg_addr, int reg_num, Int32List reg_value)
	{
		Int16List temp_short = Int16List.view(reg_value.buffer);
		_WriteRegisters(reg_addr, reg_num*2, temp_short);
	}
	Future<int> ReadSingleRegister_Int32(int reg_addr) async
	{
		Int16List temp = Int16List(2);
		await _ReadRegisters(reg_addr, 2, temp);
		Int32List  array = Int32List.view(temp.buffer);
		return array[0];
	}
	Future<Int32List> ReadRegisters_Int32(int reg_addr, int reg_num) async
	{
		Int16List temp = Int16List(reg_num*2);
		await _ReadRegisters(reg_addr, reg_num*2, temp);
		Int32List reg_value = Int32List.view(temp.buffer);
		return reg_value;
	}
	void WriteSingleRegister_Float(int reg_addr, double reg_value)
	{
		Float32List temp = Float32List(1);
		temp[0] = reg_value;
		Int16List temp_short = Int16List.view(temp.buffer);
		_WriteRegisters(reg_addr, 2, temp_short);
	}
	void WriteRegisters_Float(int reg_addr, int reg_num, Float32List reg_value)
	{
		Int16List temp_short = Int16List.view(reg_value.buffer);
		_WriteRegisters(reg_addr, reg_num*2, temp_short);
	}
	Future<double> ReadSingleRegister_Float(int reg_addr) async
	{
		Int16List temp = Int16List(2);
		await _ReadRegisters(reg_addr, 2, temp);
		Float32List  array = Float32List.view(temp.buffer);
		return array[0];
	}
	Future<Float32List> ReadRegisters_Float(int reg_addr, int reg_num) async
	{
		Int16List temp = Int16List(reg_num*2);
		await _ReadRegisters(reg_addr, reg_num*2, temp);
		Float32List reg_value = Float32List.view(temp.buffer);
		return reg_value;
	}
}

class DataConversion
{
	static int Bool_to_Int32(List<bool> array)
	{
		int result = 0;
		if (array != null)
		{
			if (array.length < 33)
			{
				array.forEach((value){
					result = (result >> 1) + (value ? 0 : 1);
				});
			}
			else
			{
				print("bool数组长度大于32，整数只有32位!!!");
			}
		}
		else
		{
			print("bool数组为空!!!");
		}
		return result;
	}
	static List<bool> Int32_to_Bool(int result)
	{
		List<bool> array =[
			false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,
			false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,
		];
		for (int i = 0; i < 32; i++)
		{
			array[32 - i - 1] = ((result >> i) % 2) == 1;
		}
		return array;
	}
}
