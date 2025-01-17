USE [TRIVIET_PRO]
GO
/****** Object:  StoredProcedure [dbo].[spIMP_PHIEU_XUAT_ONLINE]    Script Date: 18/09/2024 11:04:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Ngan Long
-- Create date: 
-- Description:	
-- =============================================
ALTER PROCEDURE [dbo].[spIMP_PHIEU_XUAT_ONLINE] 
	@pLCT	nvarchar(20) = '01',
	@pMAKHO nvarchar(20) = '01',
	@pUPDATE	bit = 0,
	@UID	int = 0,
	@TRANSNO	int = null
		
AS
BEGIN

DECLARE
	@RET int = 0,
	@CREATE_DATE datetime,
	@LOC	nvarchar(5),
	@roundGia	int = 0, 
		@roundGiaVAT	int = 2,
		@roundTienVAT	int = 2,
		@roundThanhtien	int = 0,
		@HTGIA_CO_VAT		nvarchar(70),
		@HTGIA			nvarchar(70)
	
	SET NOCOUNT ON;   
set @CREATE_DATE = getdate()
select @LOC = DEFAULT_LOC from SYS_PARAM
select @HTGIA_CO_VAT = MA_HOTRO from V_HINHTHUC_GIA where MA = '02'
select @HTGIA = @HTGIA_CO_VAT

--Update cho phù hợp số liệu
update	IMP_CHUNGTU_ONLINE
   set	MADT = UPPER(MADT),
		MADT2 = UPPER(MADT2),
		MAKHO = UPPER(MAKHO),
		PHIEUGIAOHANG = LTRIM(RTRIM(PHIEUGIAOHANG)),
		MAVT = LTRIM(RTRIM(MAVT_TEXT))
 where TransNo = @TRANSNO

--Kiểm tra dữ liệu hợp lệ tại Master
update	IMP_CHUNGTU_ONLINE
  set	ErrCode = N'E_BLANK: Chưa có ngày'
where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
  and	ISNULL(NGAY, 0) = 0

update	IMP_CHUNGTU_ONLINE
  set	ErrCode = N'E_BLANK: Chưa có Số đơn hàng'
where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
  and	ISNULL(PHIEUGIAOHANG, '') = ''

if @pUPDATE = 1 -- Đang chọn chức năng Update phiếu đã có trong phần mềm
begin
	update	IMP_CHUNGTU_ONLINE
	  set	ErrCode = N'E_NOTIN: Số đơn hàng chưa có trong Phần mềm'
	where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
	  and	ISNULL(PHIEUGIAOHANG, '') not in (select PHIEUGIAOHANG from R_XUATHANG where isnull(PHIEUGIAOHANG, '') <> '')
end else -- Thêm mới Số đơn hàng chưa có trong phần mềm
begin
	update	IMP_CHUNGTU_ONLINE
	  set	ErrCode = N'E_EXISTS: Số đơn hàng đã có trong phần mềm'
	where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
	  and	ISNULL(PHIEUGIAOHANG, '') <> ''
	  and	ISNULL(PHIEUGIAOHANG, '') in (select PHIEUGIAOHANG from R_XUATHANG)
end

update	IMP_CHUNGTU_ONLINE
  set	ErrCode = N'E_BLANK: Mã sàn TMĐT không đúng'
where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
  and	((ISNULL(MADT, '') = '') or (ISNULL(MADT, '') not in (select MADT from DM_KH_ONLINE)))

update	IMP_CHUNGTU_ONLINE
  set	ErrCode = N'E_BLANK: Mã khách hàng không đúng'
where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
  and	((ISNULL(MADT2, '') = '')  or  (ISNULL(MADT2, '') not in (select MADT from DM_KH)))

update	IMP_CHUNGTU_ONLINE
  set	ErrCode = N'E_BLANK: Mã kho không đúng'
where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
  and	((ISNULL(MAKHO, '') = '')  or  (ISNULL(MAKHO, '') not in (select MAKHO from DM_KHO)))

update	IMP_CHUNGTU_ONLINE
  set	ErrCode = N'E_BLANK: Tình trạng đơn hàng không đúng'
where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
  and	((ISNULL(TINHTRANG, '') = '')  or  (ISNULL(TINHTRANG, '') not in (select MA from V_XUATHANG_ONLINE_TINHTRANG)))

update	IMP_CHUNGTU_ONLINE
  set	ErrCode = N'E_BLANK: Mã hàng không đúng'
where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
  and	((ISNULL(MAVT, '') = '')  or  (ISNULL(MAVT, '') not in (select MAVT from DM_VT_FULL)))

update	IMP_CHUNGTU_ONLINE
  set	ErrCode = N'E_DUP: Mã hàng bị trùng trong đơn hàng'
 from	(select PHIEUGIAOHANG, MAVT, count(MAVT) SL_MA from IMP_CHUNGTU_ONLINE where TransNo = @TRANSNO group by PHIEUGIAOHANG, MAVT having count(MAVT) > 1) a
where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
  and	a.PHIEUGIAOHANG = IMP_CHUNGTU_ONLINE.PHIEUGIAOHANG
  and	a.MAVT = IMP_CHUNGTU_ONLINE.MAVT

update	imp
   set	LOAITHUE = vt.LOAITHUE,
		THUE_SUAT = vt.VAT_VAO
  from	IMP_CHUNGTU_ONLINE imp join DM_VT_FULL vt on imp.MAVT = vt.MAVT
 where	isnull(imp.ErrCode, '') = '' and	TransNo = @TRANSNO

update	IMP_CHUNGTU_ONLINE
   set	ErrCode = N'E_VAT: Mã hàng có thuế suất không hợp lệ'
  from	IMP_CHUNGTU_ONLINE
 where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
   and	((ISNULL(LOAITHUE, '') = '')  or  (ISNULL(LOAITHUE, '') not in (select MALT from DM_LOAITHUE)))

update	IMP_CHUNGTU_ONLINE
  set	ErrCode = N'E_INFILE: Có chi tiết bị sai trong Đơn hàng'
 where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
   and	PHIEUGIAOHANG in (select PHIEUGIAOHANG from IMP_CHUNGTU_ONLINE where isnull(ErrCode, '') <> '' and	TransNo = @TRANSNO)  
   
 update	IMP_CHUNGTU_ONLINE
  set	ErrCode = N'E_GTGT: Phiếu đã được xuất hóa đơn GTGT'
 where	isnull(IMP_CHUNGTU_ONLINE.ErrCode, '') = '' and	TransNo = @TRANSNO
   and	PHIEUGIAOHANG in (select PHIEUGIAOHANG from R_XUATHANG where isnull(HOADON_NGAY, 0) <> 0) 


-- Tạo table master
if OBJECT_ID('tempdb..#impChungtuOnline') is not null
	exec('drop table #impChungtuOnline')

create table #impChungtuOnline (
	TransNo int,
	[KHOA] [uniqueidentifier],
	[LCT] [nvarchar](5) NULL,
	[NGAY] [datetime] NULL,
	[SCT] [nvarchar](50) NULL,
	[MADT] [nvarchar](20) NULL,
	[MADT2] [nvarchar](20) NULL,
	[MAKHO] [nvarchar](5) NULL,
	[NGAY2] [datetime] NULL,
	[NGAY3] [datetime] NULL,
	
	[SOLUONG] [float] NULL,
	[SOLUONG_BO] [float] NULL,
	[THANHTIEN] [float] NULL,
	[TL_CKMH] [float] NULL,
	[SOTIEN_CKMH] [float] NULL,
	[THANHTIEN_SAU_CKMH] [float] NULL,
	[TL_CKHD] [float] NULL,
	[SOTIEN_CKHD] [float] NULL,
	[THANHTIEN_SAU_CKHD] [float] NULL,
	[THANHTIEN_CHUA_VAT_CL] [float] NULL,
	[THANHTIEN_CL] [float] NULL,
	[THANHTIEN_CHUA_VAT] [float] NULL,
	[THANHTIEN_CHUA_VAT_5] [float] NULL,
	[THANHTIEN_CHUA_VAT_8] [float] NULL,
	[THANHTIEN_CHUA_VAT_10] [float] NULL,
	[THANHTIEN_CHUA_VAT_KHAC] [float] NULL,
	[TIEN_THUE_CHUA_CL] [float] NULL,
	[TIEN_THUE_CL] [float] NULL,
	[TIEN_THUE] [float] NULL,
	[TIEN_THUE_5] [float] NULL,
	[TIEN_THUE_8] [float] NULL,
	[TIEN_THUE_10] [float] NULL,
	[TIEN_THUE_KHAC] [float] NULL,
	[THANHTOAN] [float] NULL,
	[THANHTOAN_KCT] [float] NULL,
	[THANHTOAN_0] [float] NULL,
	[THANHTOAN_5] [float] NULL,
	[THANHTOAN_8] [float] NULL,
	[THANHTOAN_10] [float] NULL,
	[THANHTOAN_KHAC] [float] NULL,
	[THANHTIEN_SI] [float] NULL,
	[THANHTIEN_LE] [float] NULL,
	[HINHTHUC_GIA] [nvarchar](70) NULL,
	[LOAITHUE] [nvarchar](20) NULL,
	[THUE_SUAT] [float] NULL,
	[DGIAI] [ntext] NULL,
	[CREATE_BY] [int] NULL,
	[UPDATE_BY] [int] NULL,
	[DELETE_BY] [int] NULL,
	[CREATE_DATE] [datetime] NULL,
	[UPDATE_DATE] [datetime] NULL,
	[DELETE_DATE] [datetime] NULL,
	[LOC] [nvarchar](5) NULL,

	[PHIEUGIAOHANG] [nvarchar](50) NULL,
	[SOVANDON] [nvarchar](50) NULL,
	[TINHTRANG] [nvarchar](70) NULL,
	[TINHTRANG_GHICHU] [nvarchar](200) NULL,
	[SAN_TAIKHOAN] [nvarchar](50) NULL,
	[SAN_HOTEN] [nvarchar](200) NULL,
	[HD_KHACHHANG] [bit] NULL,
	[HD_KHOA] [uniqueidentifier] NULL,
	[HD_NMUA] [nvarchar](200) NULL,
	[HD_DONVI] [nvarchar](200) NULL,
	[HD_DCHI] [nvarchar](200) NULL,
	[HD_DTHOAI] [nvarchar](100) NULL,
	[HD_EMAIL] [nvarchar](100) NULL,
	[HD_HTTT] [nvarchar](50) NULL,
	[HD_MST] [nvarchar](50) NULL,
	[HD_SOTK] [nvarchar](50) NULL,
	[HD_PHI] bit null,
	[HD_PHI_GIAMGIA] [float] NULL,
	[HD_PHI_VANCHUYEN] [float] NULL,
	[HD_PHI_HOANXU] [float] NULL,
	[HD_PHI_KHAC] [float] NULL,
	[HD_PHI_TONG] [float] NULL,
	[HD_PHIVAT_TRAHANG] [float] NULL,
	[HD_PHIVAT_CODINH] [float] NULL,
	[HD_PHIVAT_DICHVU] [float] NULL,
	[HD_PHIVAT_THANHTOAN] [float] NULL,
	[HD_PHIVAT_SAN] [float] NULL,
	[HD_PHIVAT_QUANGCAO] [float] NULL,
	[HD_PHIVAT_SANCK] [float] NULL,
	[HD_PHIVAT_HOAHONG] [float] NULL,
	[HD_PHIVAT_PHAT] [float] NULL,
	[HD_PHIVAT_KHAC] [float] NULL,
	[HD_PHIVAT_TONG] [float] NULL,

	[PHI_GIAMGIA] [float] NULL,
	[PHI_VANCHUYEN] [float] NULL,
	[PHI_HOANXU] [float] NULL,
	[PHI_KHAC] [float] NULL,
	[PHI_TONG] [float] NULL,
	[PHIVAT_TRAHANG] [float] NULL,
	[PHIVAT_CODINH] [float] NULL,
	[PHIVAT_DICHVU] [float] NULL,
	[PHIVAT_THANHTOAN] [float] NULL,
	[PHIVAT_SAN] [float] NULL,
	[PHIVAT_QUANGCAO] [float] NULL,
	[PHIVAT_SANCK] [float] NULL,
	[PHIVAT_HOAHONG] [float] NULL,
	[PHIVAT_PHAT] [float] NULL,
	[PHIVAT_KHAC] [float] NULL,
	[PHIVAT_TONG] [float] NULL
)

-- Tạo table detail
if OBJECT_ID('tempdb..#impChungtuOnlineCT') is not null
	exec('drop table #impChungtuOnlineCT')
CREATE TABLE #impChungtuOnlineCT(
	TransNo int,
	[KHOACT] [uniqueidentifier],
	[KHOA] [uniqueidentifier] NULL,
	[PHIEUGIAOHANG] [nvarchar](50) NULL,
	[STT] [int] NULL,
	[MAVT] [nvarchar](15) NULL,
	[MABH_BO] [nvarchar](15) NULL,
	[TENVT] [nvarchar](200) NULL,
	[DVT] [nvarchar](20) NULL,
	[QD1] [int] NULL,
	[DVT_BOX] [nvarchar](20) NULL,
	[SOLUONG] [float] NULL,
	[SOLUONG_BOX] [float] NULL,
	[SOLUONG_BOX_LE] [float] NULL,
	[GIAVON] float NULL,
	[DONGIA] [float] NULL,
	[DONGIA_BOX] [float] NULL,
	[THANHTIEN] [float] NULL,
	[TL_CKMH] [float] NULL,
	[DONGIA_CKMH] [float] NULL,
	[DONGIA_BOX_CKMH] [float] NULL,
	[SOTIEN_CKMH] [float] NULL,
	[THANHTIEN_SAU_CKMH] [float] NULL,
	[TL_CKHD] [float] NULL,
	[DONGIA_CKHD] [float] NULL,
	[DONGIA_BOX_CKHD] [float] NULL,
	[SOTIEN_CKHD] [float] NULL,
	[THANHTIEN_SAU_CKHD] [float] NULL,
	[LOAITHUE] [nvarchar](20) NULL,
	[THUE_SUAT] [float] NULL,
	[DONGIA_CHUA_VAT] [float] NULL,
	[DONGIA_BOX_CHUA_VAT] [float] NULL,
	[THANHTIEN_CHUA_VAT_CL] [float] NULL,
	[THANHTIEN_CL] [float] NULL,
	[THANHTIEN_CHUA_VAT] [float] NULL,
	[THANHTIEN_CHUA_VAT_5] [float] NULL,
	[THANHTIEN_CHUA_VAT_8] [float] NULL,
	[THANHTIEN_CHUA_VAT_10] [float] NULL,
	[THANHTIEN_CHUA_VAT_KHAC] [float] NULL,
	[TIEN_THUE_CHUA_CL] [float] NULL,
	[TIEN_THUE_CL] [float] NULL,
	[TIEN_THUE] [float] NULL,
	[TIEN_THUE_5] [float] NULL,
	[TIEN_THUE_8] [float] NULL,
	[TIEN_THUE_10] [float] NULL,
	[TIEN_THUE_KHAC] [float] NULL,
	[THANHTOAN] [float] NULL,
	[THANHTOAN_KCT] [float] NULL,
	[THANHTOAN_0] [float] NULL,
	[THANHTOAN_5] [float] NULL,
	[THANHTOAN_8] [float] NULL,
	[THANHTOAN_10] [float] NULL,
	[THANHTOAN_KHAC] [float] NULL,
	[BO] [bit] NULL,
	[SOLUONG_BO] [float] NULL,
	[SOLUONG_BO_DANHMUC] [float] NULL,
	[KHONG_TINHTON] [bit] NULL,
	[DONGIA_SI] [float] NULL,
	[THANHTIEN_SI] [float] NULL,
	[DONGIA_LE] [float] NULL,
	[THANHTIEN_LE] [float] NULL,
	[PHI_GIAMGIA] [float] NULL,
	[PHI_VANCHUYEN] [float] NULL,
	[PHI_HOANXU] [float] NULL,
	[PHI_KHAC] [float] NULL,
	[PHI_TONG] [float] NULL,
	[PHIVAT_TRAHANG] [float] NULL,
	[PHIVAT_CODINH] [float] NULL,
	[PHIVAT_DICHVU] [float] NULL,
	[PHIVAT_THANHTOAN] [float] NULL,
	[PHIVAT_SAN] [float] NULL,
	[PHIVAT_QUANGCAO] [float] NULL,
	[PHIVAT_SANCK] [float] NULL,
	[PHIVAT_HOAHONG] [float] NULL,
	[PHIVAT_PHAT] [float] NULL,
	[PHIVAT_KHAC] [float] NULL,
	[PHIVAT_TONG] [float] NULL,
	[GHICHU] [nvarchar](200) NULL
)

-- Tạo table eHoaDon
if OBJECT_ID('tempdb..#impeHoaDon') is not null
	exec('drop table #impeHoaDon')

create table #impeHoaDon (
	TransNo int,
	[KHOA] [uniqueidentifier],
	[PHIEUGIAOHANG] [nvarchar](50) NULL,
    [DoiTacLienKet] [nvarchar](20) NULL,
    [InvoiceStatusID] [int] NULL,
    [InvoiceGUID] [nvarchar](50) NULL,
    [HoaDon_KyHieu] [nvarchar](50) NULL,
    [HoaDon_So] [nvarchar](50) NULL,
    [HoaDon_Mau] [nvarchar](50) NULL,
    [HoaDon_Ngay] [datetime] NULL,
    [HoaDon_NguoiMua] [nvarchar](250) NULL,
    [HoaDon_DonVi] [nvarchar](250) NULL,
    [HoaDon_DiaChi] [nvarchar](250) NULL,
    [HoaDon_DienThoai] [nvarchar](50) NULL,
    [HoaDon_MaSoThue] [nvarchar](50) NULL,
    [HoaDon_SoTaiKhoan] [nvarchar](50) NULL,
    [HoaDon_HinhThucThanhToan] [nvarchar](50) NULL,
    [HoaDon_MaTraCuu] [nvarchar](50) NULL,
    [HoaDon_Email] [nvarchar](250) NULL,
    [HoaDon_LyDo] [nvarchar](250) NULL,
    [KhoaPhieuGoc] [uniqueidentifier] NULL,
    [LctPhieuGoc] [nvarchar](5) NULL,
    [SctPhieuGoc] [nvarchar](20) NULL,
    [NgayPhatHanh] [datetime] NULL,
    [MaCuaCQT] [nvarchar](250) NULL,
    [CREATE_BY] [int] NULL,
    [UPDATE_BY] [int] NULL, 
    [DELETE_BY] [int] NULL, 
    [CREATE_DATE] [datetime] NULL,
    [UPDATE_DATE] [datetime] NULL,
    [DELETE_DATE] [datetime] NULL,
)

--Fill số liệu vào 2 table
insert into #impChungtuOnline
(
	TransNo,
		[PHIEUGIAOHANG] , [KHOA] ,[LCT] ,[NGAY], LOAITHUE, THUE_SUAT
		,[MADT] ,[MAKHO] ,[CREATE_BY] ,[UPDATE_BY] ,[CREATE_DATE] ,[UPDATE_DATE] ,[LOC], HINHTHUC_GIA
	  ,[SOVANDON] ,[TINHTRANG] ,[TINHTRANG_GHICHU] ,[MADT2] ,[NGAY2] ,[NGAY3] ,[SAN_TAIKHOAN] ,[SAN_HOTEN] 
	  ,[HD_KHACHHANG]
	  ,[HD_NMUA] ,[HD_DONVI] ,[HD_DCHI] ,[HD_DTHOAI] ,[HD_EMAIL] ,[HD_HTTT] ,[HD_MST] ,[HD_SOTK] 
	  ,[HD_PHI_GIAMGIA] ,[HD_PHI_VANCHUYEN] ,[HD_PHI_HOANXU] ,[HD_PHI_KHAC] 
	  ,[HD_PHIVAT_TRAHANG] ,[HD_PHIVAT_CODINH] ,[HD_PHIVAT_DICHVU] ,[HD_PHIVAT_THANHTOAN] ,[HD_PHIVAT_SAN] ,[HD_PHIVAT_QUANGCAO] ,[HD_PHIVAT_SANCK]
      ,[HD_PHIVAT_HOAHONG] ,[HD_PHIVAT_PHAT] ,[HD_PHIVAT_KHAC] 
)
select distinct ds.TransNo, [PHIEUGIAOHANG] , newid() ,@pLCT ,max([NGAY]), max(isnull(LOAITHUE, '')), max(isnull(THUE_SUAT, 0))
		,[MADT] ,[MAKHO] , @UID ,@UID , @CREATE_DATE ,@CREATE_DATE , @LOC, @HTGIA
	  ,[SOVANDON] , tt.MA_HOTRO ,[TINHTRANG_GHICHU] ,[MADT2] ,max([NGAY2]) ,max([NGAY3]) ,[SAN_TAIKHOAN] ,[SAN_HOTEN] 
	  ,case when upper(isnull(ds.[HD_KHACHHANG_TEXT], '')) = 'YES' then 1 else 0 end
	  --,ds.[HD_KHACHHANG]
	  ,[HD_NMUA] ,[HD_DONVI] ,[HD_DCHI] ,[HD_DTHOAI] ,[HD_EMAIL] ,[HD_HTTT] ,[HD_MST] ,[HD_SOTK]       
	  ,max(isnull([HD_PHI_GIAMGIA], 0)) ,max(isnull([HD_PHI_VANCHUYEN], 0)) ,max(isnull([HD_PHI_HOANXU], 0)) ,max(isnull([HD_PHI_KHAC], 0))
	  ,max(isnull([HD_PHIVAT_TRAHANG], 0)) ,max(isnull([HD_PHIVAT_CODINH], 0)) ,max(isnull([HD_PHIVAT_DICHVU], 0)) ,max(isnull([HD_PHIVAT_THANHTOAN], 0)) ,max(isnull([HD_PHIVAT_SAN], 0)) ,max(isnull([HD_PHIVAT_QUANGCAO], 0)) ,max(isnull([HD_PHIVAT_SANCK], 0))
      ,max(isnull([HD_PHIVAT_HOAHONG], 0)) ,max(isnull([HD_PHIVAT_PHAT], 0)) ,max(isnull([HD_PHIVAT_KHAC], 0)) 
  from IMP_CHUNGTU_ONLINE ds join V_XUATHANG_ONLINE_TINHTRANG tt on ds.TINHTRANG = tt.MA
 where	isnull(ds.ErrCode, '') = '' and	ds.TransNo = @TRANSNO
group by ds.TransNo, [PHIEUGIAOHANG], [MADT] ,[MAKHO], [SOVANDON] , tt.MA_HOTRO ,[TINHTRANG_GHICHU] ,[MADT2], [SAN_TAIKHOAN] ,[SAN_HOTEN]
			,[HD_KHACHHANG_TEXT],[HD_NMUA] ,[HD_DONVI] ,[HD_DCHI] ,[HD_DTHOAI] ,[HD_EMAIL] ,[HD_HTTT] ,[HD_MST] ,[HD_SOTK] 

INSERT INTO #impChungtuOnlineCT
           (TransNo
		   ,[KHOACT] ,[KHOA], [PHIEUGIAOHANG]
           ,[MAVT] ,[TENVT] ,[DVT] ,[QD1] ,[DVT_BOX]
           ,[SOLUONG] , [GIAVON], [DONGIA]
           ,[SOTIEN_CKMH] , THANHTIEN_SAU_CKMH
           ,[TL_CKHD] ,[SOTIEN_CKHD]
           ,[LOAITHUE] ,[THUE_SUAT] 
           ,[BO] ,[KHONG_TINHTON]           
		   ,[DONGIA_SI] ,[THANHTIEN_SI] ,[DONGIA_LE] ,[THANHTIEN_LE]           
		   ,[PHI_GIAMGIA] ,[PHI_VANCHUYEN] ,[PHI_HOANXU] ,[PHI_KHAC] , [PHI_TONG]
           ,[PHIVAT_TRAHANG] ,[PHIVAT_CODINH] ,[PHIVAT_DICHVU] ,[PHIVAT_THANHTOAN]  ,[PHIVAT_SAN] ,[PHIVAT_QUANGCAO]
           ,[PHIVAT_SANCK] ,[PHIVAT_HOAHONG] ,[PHIVAT_PHAT] ,[PHIVAT_KHAC] ,[PHIVAT_TONG])
select	   imp.TransNo
			,NEWID() ,tmp.[KHOA], imp.PHIEUGIAOHANG
           ,imp.[MAVT] ,vt.[TENVT] ,vt.[DVT] ,vt.[QD1] ,vt.[DVT_BOX] 
		   ,isnull(imp.[SOLUONG], 0) , isnull(vt.GIAVON, 0), imp.DONGIA
		   ,imp.[SOTIEN_CKMH], imp.THANHTIEN_SAU_CKMH
           ,0
           ,0
           ,vt.[LOAITHUE] ,vt.VAT_RA
           ,isnull(vt.[BO], 0) ,isnull(vt.[KHONG_TINHTON], 0)
           
		   ,vt.[GIASI] , isnull(imp.SOLUONG, 0) * isnull(GIASI, 0) ,vt.GIABAN ,isnull(imp.SOLUONG, 0) * isnull(GIABAN, 0)
           
		   ,isnull(imp.[PHI_GIAMGIA], 0) ,isnull(imp.[PHI_VANCHUYEN], 0) ,isnull(imp.[PHI_HOANXU], 0) ,isnull(imp.[PHI_KHAC], 0)
           ,isnull(imp.PHI_GIAMGIA, 0) + isnull(imp.PHI_VANCHUYEN, 0) + isnull(imp.PHI_HOANXU, 0) + isnull(imp.PHI_KHAC, 0) [PHI_TONG]
           ,isnull(imp.[PHIVAT_TRAHANG], 0) ,isnull(imp.[PHIVAT_CODINH], 0) ,isnull(imp.[PHIVAT_DICHVU], 0) ,isnull(imp.[PHIVAT_THANHTOAN], 0) ,isnull(imp.[PHIVAT_SAN], 0)
           ,isnull(imp.[PHIVAT_QUANGCAO], 0) ,isnull(imp.[PHIVAT_SANCK], 0) ,isnull(imp.[PHIVAT_HOAHONG], 0) ,isnull(imp.[PHIVAT_PHAT], 0) ,isnull(imp.[PHIVAT_KHAC], 0)
           ,isnull(imp.[PHIVAT_TRAHANG], 0) + isnull(imp.[PHIVAT_CODINH], 0) + isnull(imp.[PHIVAT_DICHVU], 0) + isnull(imp.[PHIVAT_THANHTOAN], 0) + 
				isnull(imp.[PHIVAT_SAN], 0) + isnull(imp.[PHIVAT_QUANGCAO], 0) + isnull(imp.[PHIVAT_SANCK], 0) + isnull(imp.[PHIVAT_HOAHONG], 0) +
				isnull(imp.[PHIVAT_PHAT], 0) + isnull(imp.[PHIVAT_KHAC], 0) [PHIVAT_TONG]
           
  from	IMP_CHUNGTU_ONLINE imp join #impChungtuOnline tmp on imp.PHIEUGIAOHANG = tmp.PHIEUGIAOHANG
			join DM_VT_FULL vt on imp.MAVT = vt.MAVT
 where	isnull(imp.ErrCode, '') = '' and	imp.TransNo = @TRANSNO

  --Cập nhật Số chứng từ đã có từ Phần mềm
update	a
  set	SCT = xuat.SCT,	
		KHOA = xuat.KHOA
 from	#impChungtuOnline a join R_XUATHANG xuat on a.PHIEUGIAOHANG = xuat.PHIEUGIAOHANG 
 where	xuat.LCT = @pLCT

--cập nhật KHOACT cho các Phiếu đã có trong phần mềm
 update	b
  set	KHOA = xuat.KHOA,
		KHOACT = case when xuatct.KHOACT is null then NEWID() else xuatct.KHOACT end
 from	#impChungtuOnlineCT b join R_XUATHANG xuat on b.PHIEUGIAOHANG = xuat.PHIEUGIAOHANG 
				left join XUATHANG_CT xuatct on xuat.KHOA = xuatct.KHOA and b.MAVT = xuatct.MAVT
 where	xuat.LCT = @pLCT

--=====================================Bỏ Những phiếu đã xuất hóa đơn lên Bkav=============================================

delete #impChungtuOnline where KHOA  in (select khoaphieugoc from eHoaDon ehd where isnull(ehd.InvoiceGUID,'') <> '')
delete #impChungtuOnlineCT where KHOA  in (select khoaphieugoc from eHoaDon ehd where isnull(ehd.InvoiceGUID,'') <> '')

--======================================================////===============================================================

update	#impChungtuOnlineCT
   set	STT = a.STT
  from (select ROW_NUMBER () over(PARTITION BY KHOA order by TENVT, MAVT) STT, KHOACT from #impChungtuOnlineCT) a
 where #impChungtuOnlineCT.KHOACT = a.KHOACT

--Cập nhật tính toán cho Chi tiết
update	#impChungtuOnlineCT
   set	DONGIA = isnull(DONGIA_LE, 0),
		SOTIEN_CKMH = (isnull(DONGIA_LE, 0) * isnull(SOLUONG, 0)) - isnull(THANHTIEN_SAU_CKMH, 0)
 where	isnull(DONGIA, 0) = 0 -- Đối với sàn không có Đơn giá --> Áp giá bán lẻ vào Đơn giá

update	#impChungtuOnlineCT
   set	SOLUONG_BOX = isnull(SOLUONG, 0) * isnull(QD1, 1),
		DONGIA_BOX = isnull(DONGIA, 0) * isnull(QD1, 1),
		THANHTIEN = isnull(DONGIA, 0) * isnull(SOLUONG, 0)

update	#impChungtuOnlineCT
   set	TL_CKMH = case when isnull(THANHTIEN, 0) = 0 then 0 else (isnull(SOTIEN_CKMH, 0) / isnull(THANHTIEN, 0)) * 100 end

update	#impChungtuOnlineCT
   set	DONGIA_CKMH = round(isnull(DONGIA, 0) * (1 - isnull(TL_CKMH, 0)/100), @roundGiaVAT)

update	#impChungtuOnlineCT
   set	DONGIA_BOX_CKMH = isnull(DONGIA_CKMH, 0) * case when isnull(QD1, 1) = 0 then 1 else isnull(QD1, 1) end,
		THANHTIEN_SAU_CKMH = isnull(THANHTIEN, 0) - isnull(SOTIEN_CKMH, 0)

--Cập nhật Tổng Số tiền Trước chi phí vào master để lấy Số liệu rã Chi phí ở chi tiết
update	#impChungtuOnline
	   set	
			THANHTIEN_SAU_CKMH = a.THANHTIEN_SAU_CKMH
			
	from	(select	KHOA, sum(isnull(THANHTIEN_SAU_CKMH, 0)) THANHTIEN_SAU_CKMH
				from	#impChungtuOnlineCT
				group by KHOA) a
   where	#impChungtuOnline.KHOA = a.KHOA

--Cập nhật Đơn hàng có Phí tổng hóa đơn
update	#impChungtuOnline
   set	HD_PHI = 1
 where	isnull(HD_PHI_GIAMGIA, 0) <> 0
    or	isnull(HD_PHI_HOANXU, 0) <> 0
	or	isnull(HD_PHI_KHAC, 0) <> 0
	or	isnull(HD_PHI_VANCHUYEN, 0) <> 0
	or	isnull(HD_PHIVAT_CODINH, 0) <> 0
	or	isnull(HD_PHIVAT_DICHVU, 0) <> 0
	or	isnull(HD_PHIVAT_HOAHONG, 0) <> 0
	or	isnull(HD_PHIVAT_KHAC, 0) <> 0
	or	isnull(HD_PHIVAT_PHAT, 0) <> 0
	or	isnull(HD_PHIVAT_QUANGCAO, 0) <> 0
	or	isnull(HD_PHIVAT_SAN, 0) <> 0
	or	isnull(HD_PHIVAT_SANCK, 0) <> 0
	or	isnull(HD_PHIVAT_THANHTOAN, 0) <> 0
	or	isnull(HD_PHIVAT_TRAHANG, 0) <> 0

--Cập nhật Số tiền Phí tổng đơn hàng chia xuống chi tiết
update	b
   set	PHI_GIAMGIA = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHI_GIAMGIA, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHI_HOANXU = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHI_HOANXU, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHI_VANCHUYEN = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHI_VANCHUYEN, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHI_KHAC = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHI_KHAC, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHIVAT_CODINH = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHIVAT_CODINH, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHIVAT_DICHVU = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHIVAT_DICHVU, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHIVAT_HOAHONG = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHIVAT_HOAHONG, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHIVAT_KHAC = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHIVAT_KHAC, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHIVAT_PHAT = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHIVAT_PHAT, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHIVAT_QUANGCAO = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHIVAT_QUANGCAO, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHIVAT_SAN = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHIVAT_SAN, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHIVAT_SANCK = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHIVAT_SANCK, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHIVAT_THANHTOAN = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHIVAT_THANHTOAN, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end,
		PHIVAT_TRAHANG = case isnull(a.THANHTIEN_SAU_CKMH, 0) when 0 then 0 else round((isnull(b.THANHTIEN_SAU_CKMH, 0) * isnull(a.HD_PHIVAT_TRAHANG, 0)) / isnull(a.THANHTIEN_SAU_CKMH, 1), 0) end
  from	#impChungtuOnline a join #impChungtuOnlineCT b on a.KHOA = b.KHOA
 where	isnull(a.HD_PHI, 0) = 1

--Cập nhật Phí tổng
update	#impChungtuOnlineCT
   set	PHI_TONG = isnull(PHI_GIAMGIA, 0) + isnull(PHI_HOANXU, 0) + isnull(PHI_VANCHUYEN, 0) + isnull(PHI_KHAC, 0),
		PHIVAT_TONG = isnull(PHIVAT_CODINH, 0) + isnull(PHIVAT_DICHVU, 0) + isnull(PHIVAT_HOAHONG, 0) + isnull(PHIVAT_PHAT, 0) +
							isnull(PHIVAT_QUANGCAO, 0) + isnull(PHIVAT_SAN, 0) + isnull(PHIVAT_SANCK, 0) + isnull(PHIVAT_THANHTOAN, 0) +
							isnull(PHIVAT_TRAHANG, 0) + isnull(PHIVAT_KHAC, 0)

--Cập nhật Tổng số tiền Phí vào master
update	#impChungtuOnline
	   set			
			PHI_GIAMGIA = ds.PHI_GIAMGIA,
			PHI_HOANXU = ds.PHI_HOANXU,
			PHI_VANCHUYEN = ds.PHI_VANCHUYEN,
			PHI_KHAC = ds.PHI_KHAC,
			PHI_TONG = ds.PHI_TONG,
			PHIVAT_CODINH = ds.PHIVAT_CODINH,
			PHIVAT_DICHVU = ds.PHIVAT_DICHVU,
			PHIVAT_HOAHONG = ds.PHIVAT_HOAHONG,
			PHIVAT_KHAC = ds.PHIVAT_KHAC,
			PHIVAT_PHAT = ds.PHIVAT_PHAT,
			PHIVAT_QUANGCAO = ds.PHIVAT_QUANGCAO,
			PHIVAT_SAN = ds.PHIVAT_SAN,
			PHIVAT_SANCK = ds.PHIVAT_SANCK,
			PHIVAT_THANHTOAN = ds.PHIVAT_THANHTOAN,
			PHIVAT_TRAHANG = ds.PHIVAT_TRAHANG,
			PHIVAT_TONG = ds.PHIVAT_TONG
	from	(select	KHOA, 
					sum(isnull(PHI_GIAMGIA, 0)) PHI_GIAMGIA,
					sum(isnull(PHI_HOANXU, 0)) PHI_HOANXU,
					sum(isnull(PHI_VANCHUYEN, 0)) PHI_VANCHUYEN,
					sum(isnull(PHI_KHAC, 0)) PHI_KHAC,
					sum(isnull(PHI_TONG, 0)) PHI_TONG,
					sum(isnull(PHIVAT_CODINH, 0)) PHIVAT_CODINH,
					sum(isnull(PHIVAT_DICHVU, 0)) PHIVAT_DICHVU,
					sum(isnull(PHIVAT_HOAHONG, 0)) PHIVAT_HOAHONG,
					sum(isnull(PHIVAT_KHAC, 0)) PHIVAT_KHAC,
					sum(isnull(PHIVAT_PHAT, 0)) PHIVAT_PHAT,
					sum(isnull(PHIVAT_QUANGCAO, 0)) PHIVAT_QUANGCAO,
					sum(isnull(PHIVAT_SAN, 0)) PHIVAT_SAN,
					sum(isnull(PHIVAT_SANCK, 0)) PHIVAT_SANCK,
					sum(isnull(PHIVAT_THANHTOAN, 0)) PHIVAT_THANHTOAN,
					sum(isnull(PHIVAT_TRAHANG, 0)) PHIVAT_TRAHANG,
					sum(isnull(PHIVAT_TONG, 0)) PHIVAT_TONG
				from	#impChungtuOnlineCT
				group by KHOA) ds
   where	#impChungtuOnline.KHOA = ds.KHOA

-- Tiếp tục tính chi tiết Số tiền sau Chi phí
	update	#impChungtuOnlineCT
	   set	SOTIEN_CKHD = round(isnull(PHI_TONG, 0), @roundThanhtien),
			THANHTIEN_SAU_CKHD = round(isnull(THANHTIEN_SAU_CKMH, 0) - isnull(PHI_TONG, 0), @roundThanhtien)

	update	#impChungtuOnlineCT
	   set	DONGIA_CKHD = round(isnull(THANHTIEN_SAU_CKHD, 0) / case when isnull(SOLUONG, 0) <> 0 then isnull(SOLUONG, 0) else 1 end, @roundGiaVAT)

	update	#impChungtuOnlineCT
	   set	DONGIA_BOX_CKHD = isnull(isnull(DONGIA_CKHD, 0), 0) * case when isnull(QD1, 1) = 0 then 1 else isnull(QD1, 1) end

	 --if @HTGIA = @HTGIA_CO_VAT --NTD: Chắc chắn Hình thức giá là Có VAT
	 begin
		Update  #impChungtuOnlineCT
		   set	THANHTOAN			=	 round(isnull(THANHTIEN_SAU_CKHD, 0), @roundThanhtien),
				THANHTIEN_CHUA_VAT_CL = round(isnull(DONGIA_CKHD, 0) / (1 + isnull(THUE_SUAT, 0)/100) * isnull(SOLUONG, 0), @roundGiaVAT),
				THANHTIEN_CL = 0
		update	#impChungtuOnlineCT
		   set	THANHTOAN_KCT	=	case when isnull(LOAITHUE, '') = 'KCT' then  THANHTOAN else 0 end,
				THANHTOAN_0		=	case when isnull(LOAITHUE, '') = 'T00' then  THANHTOAN else 0 end,
				THANHTOAN_5		=	case when isnull(LOAITHUE, '') = 'T05' then  THANHTOAN else 0 end,
				THANHTOAN_8		=	case when isnull(LOAITHUE, '') = 'T08' then  THANHTOAN else 0 end,
				THANHTOAN_10	=	case when isnull(LOAITHUE, '') = 'T10' then  THANHTOAN else 0 end,
				THANHTOAN_KHAC	=	case when isnull(LOAITHUE, '') not in ('KCT', 'T00', 'T05', 'T08', 'T10') then  THANHTOAN else 0 end

		Update  #impChungtuOnlineCT
		   set	THANHTIEN_CHUA_VAT		= round(isnull(THANHTIEN_CHUA_VAT_CL, 0), @roundThanhtien)
		update  #impChungtuOnlineCT
		   set	THANHTIEN_CHUA_VAT_5	=	case when isnull(LOAITHUE, '') = 'T05' then  THANHTIEN_CHUA_VAT else 0 end,
				THANHTIEN_CHUA_VAT_8	=	case when isnull(LOAITHUE, '') = 'T08' then  THANHTIEN_CHUA_VAT else 0 end,
				THANHTIEN_CHUA_VAT_10	=	case when isnull(LOAITHUE, '') = 'T10' then  THANHTIEN_CHUA_VAT else 0 end,
				THANHTIEN_CHUA_VAT_KHAC	=	case when isnull(LOAITHUE, '') not in ('T05', 'T08', 'T10') then  THANHTIEN_CHUA_VAT else 0 end
				
	
		Update  #impChungtuOnlineCT
		   set	TIEN_THUE_CHUA_CL	= round((isnull(THANHTIEN_CHUA_VAT_CL,0) * isnull(THUE_SUAT,0)/100), @roundTienVAT),
				TIEN_THUE_CL		= 0,
				TIEN_THUE			= round((isnull(THANHTIEN_CHUA_VAT_CL,0) * isnull(THUE_SUAT,0)/100), @roundTienVAT)

		update	#impChungtuOnlineCT
		   set	TIEN_THUE_5		=	case when isnull(LOAITHUE, '') = 'T05' then TIEN_THUE else 0 end,
				TIEN_THUE_8		=	case when isnull(LOAITHUE, '') = 'T08' then TIEN_THUE else 0 end,
				TIEN_THUE_10	=	case when isnull(LOAITHUE, '') = 'T10' then TIEN_THUE else 0 end,
				TIEN_THUE_KHAC	=	case when isnull(LOAITHUE, '') not in ('T05', 'T08', 'T10') then TIEN_THUE else 0 end

--==========================================Tính tiền thuế chênh lệch từng loại=========================================

		Update  #impChungtuOnlineCT
		   set	TIEN_THUE_CL = round(isnull(CANDOI_THUE_5, 0),2)
		  from	(select	KHOA, round(sum(isnull(THANHTOAN_5, 0)),0) - round(sum(isnull(TIEN_THUE_5, 0)), 2) - round(sum(isnull(THANHTIEN_CHUA_VAT_5, 0)),0) CANDOI_THUE_5
						from	#impChungtuOnlineCT
						group by KHOA) a
		 where	a.KHOA = #impChungtuOnlineCT.KHOA
		   and	isnull(a.CANDOI_THUE_5, 0) <> 0
		   and	KHOACT in (select top 1 KHOACT
											from #impChungtuOnlineCT b 
											where b.KHOA = #impChungtuOnlineCT.KHOA and isnull(LOAITHUE, '') = 'T05'
											order by STT)

		Update  #impChungtuOnlineCT
		   set	TIEN_THUE_CL = round(isnull(CANDOI_THUE_8, 0),2)
		  from	(select	KHOA, round(sum(isnull(THANHTOAN_8, 0)),0) - round(sum(isnull(TIEN_THUE_8, 0)), 2) - round(sum(isnull(THANHTIEN_CHUA_VAT_8, 0)),0) CANDOI_THUE_8
						from	#impChungtuOnlineCT
						group by KHOA) a
		 where	a.KHOA = #impChungtuOnlineCT.KHOA
		   and	isnull(a.CANDOI_THUE_8, 0) <> 0
		   and	KHOACT in (select top 1 KHOACT
											from #impChungtuOnlineCT b 
											where b.KHOA = #impChungtuOnlineCT.KHOA and isnull(LOAITHUE, '') = 'T08'
											order by STT)

		Update  #impChungtuOnlineCT
		   set	TIEN_THUE_CL = round(isnull(CANDOI_THUE_10, 0),2)
		  from	(select	KHOA, round(sum(isnull(THANHTOAN_10, 0)),0) - round(sum(isnull(TIEN_THUE_10, 0)), 2) - round(sum(isnull(THANHTIEN_CHUA_VAT_10, 0)),0) CANDOI_THUE_10
						from	#impChungtuOnlineCT
						group by KHOA) a
		 where	a.KHOA = #impChungtuOnlineCT.KHOA
		   and	isnull(a.CANDOI_THUE_10, 0) <> 0
		   and	KHOACT in (select top 1 KHOACT
											from #impChungtuOnlineCT b 
											where b.KHOA = #impChungtuOnlineCT.KHOA and isnull(LOAITHUE, '') = 'T10'
											order by STT)

--================================================Cộng tiền thuế chênh lệch=============================================

		update	#impChungtuOnlineCT
		   set	TIEN_THUE = TIEN_THUE_CHUA_CL + isnull(TIEN_THUE_CL, 0)

--=============================================Cập nhật thuế cân đối từng loại==========================================

		update	#impChungtuOnlineCT
		   set	TIEN_THUE_5		=	case when isnull(LOAITHUE, '') = 'T05' then TIEN_THUE else TIEN_THUE_5 end,
		   		TIEN_THUE_8		=	case when isnull(LOAITHUE, '') = 'T08' then TIEN_THUE else TIEN_THUE_8 end,
				TIEN_THUE_10	=	case when isnull(LOAITHUE, '') = 'T10' then TIEN_THUE else TIEN_THUE_10 end
--=========================================================///==========================================================

		Update  #impChungtuOnlineCT
		   set	THANHTIEN_CHUA_VAT	= round(isnull(THANHTIEN_CHUA_VAT_CL, 0) + isnull(THANHTIEN_CL, 0), @roundThanhtien)		
	
		Update  #impChungtuOnlineCT
		   set	DONGIA_CHUA_VAT		= round(isnull(THANHTIEN_CHUA_VAT, 0) / case when isnull(SOLUONG, 0) <> 0 then isnull(SOLUONG, 0) else 1 end, @roundGiaVAT)

		update	#impChungtuOnlineCT
		   set	DONGIA_BOX_CHUA_VAT	=	round(isnull(DONGIA_CHUA_VAT, 0) * case when isnull(QD1, 0) = 0 then 1 else QD1 end, @roundGiaVAT)
		
end
--Cập nhật Tổng Số tiền sau chi phí vào master
update	#impChungtuOnline
	   set	
			SOLUONG = a.SOLUONG,
			THANHTIEN = a.THANHTIEN,
			SOTIEN_CKMH = a.SOTIEN_CKMH,
			THANHTIEN_SAU_CKMH = a.THANHTIEN_SAU_CKMH,
			SOTIEN_CKHD = a.SOTIEN_CKHD,
			THANHTIEN_SAU_CKHD = a.THANHTIEN_SAU_CKHD,
			THANHTIEN_CHUA_VAT_CL = a.THANHTIEN_CHUA_VAT_CL,
			THANHTIEN_CL = a.THANHTIEN_CL,
			THANHTIEN_CHUA_VAT = a.THANHTIEN_CHUA_VAT,
			THANHTIEN_CHUA_VAT_5 = a.THANHTIEN_CHUA_VAT_5,
			THANHTIEN_CHUA_VAT_8 = a.THANHTIEN_CHUA_VAT_8,
			THANHTIEN_CHUA_VAT_10 = a.THANHTIEN_CHUA_VAT_10,
			THANHTIEN_CHUA_VAT_KHAC = a.THANHTIEN_CHUA_VAT_KHAC,
			TIEN_THUE_5 = a.TIEN_THUE_5,
			TIEN_THUE_8 = a.TIEN_THUE_8,
			TIEN_THUE_10 = a.TIEN_THUE_10,
			TIEN_THUE_KHAC = a.TIEN_THUE_KHAC,
			TIEN_THUE_CHUA_CL = a.TIEN_THUE_CHUA_CL,
			TIEN_THUE_CL = a.TIEN_THUE_CL,
			TIEN_THUE = round(a.TIEN_THUE, @roundThanhtien),
			THANHTOAN = a.THANHTOAN,
			THANHTOAN_KCT = a.THANHTOAN_KCT,
			THANHTOAN_0 = a.THANHTOAN_0,
			THANHTOAN_5 = a.THANHTOAN_5,
			THANHTOAN_8 = a.THANHTOAN_8,
			THANHTOAN_10 = a.THANHTOAN_10,
			THANHTOAN_KHAC = a.THANHTOAN_KHAC,

			THANHTIEN_SI = a.THANHTIEN_SI,
			THANHTIEN_LE = a.THANHTIEN_LE
	from	(select	KHOA, Sum(isnull(SOLUONG, 0)) SOLUONG,  sum(isnull(THANHTIEN, 0)) THANHTIEN, 
					sum(isnull(SOTIEN_CKMH, 0)) SOTIEN_CKMH, sum(isnull(THANHTIEN_SAU_CKMH, 0)) THANHTIEN_SAU_CKMH, sum(isnull(SOTIEN_CKHD, 0)) SOTIEN_CKHD, sum(isnull(THANHTIEN_SAU_CKHD, 0)) THANHTIEN_SAU_CKHD,
					sum(isnull(THANHTIEN_CHUA_VAT_CL, 0)) THANHTIEN_CHUA_VAT_CL, sum(isnull(THANHTIEN_CL, 0)) THANHTIEN_CL, sum(isnull(THANHTIEN_CHUA_VAT, 0)) THANHTIEN_CHUA_VAT,  sum(isnull(THANHTIEN_CHUA_VAT_5, 0)) THANHTIEN_CHUA_VAT_5,
					sum(isnull(THANHTIEN_CHUA_VAT_8, 0)) THANHTIEN_CHUA_VAT_8,  sum(isnull(THANHTIEN_CHUA_VAT_10, 0)) THANHTIEN_CHUA_VAT_10,  sum(isnull(THANHTIEN_CHUA_VAT_KHAC, 0)) THANHTIEN_CHUA_VAT_KHAC,
					sum(isnull(TIEN_THUE_5, 0)) TIEN_THUE_5, sum(isnull(TIEN_THUE_8, 0)) TIEN_THUE_8, sum(isnull(TIEN_THUE_10, 0)) TIEN_THUE_10, sum(isnull(TIEN_THUE_KHAC, 0)) TIEN_THUE_KHAC, sum(isnull(TIEN_THUE_CHUA_CL, 0)) TIEN_THUE_CHUA_CL,
					sum(isnull(TIEN_THUE_CL, 0)) TIEN_THUE_CL, sum(isnull(TIEN_THUE, 0)) TIEN_THUE, sum(isnull(THANHTOAN, 0)) THANHTOAN, sum(isnull(THANHTOAN_KCT, 0)) THANHTOAN_KCT, sum(isnull(THANHTOAN_0, 0)) THANHTOAN_0,
					sum(isnull(THANHTOAN_5, 0)) THANHTOAN_5, sum(isnull(THANHTOAN_8, 0)) THANHTOAN_8, sum(isnull(THANHTOAN_10, 0)) THANHTOAN_10, sum(isnull(THANHTOAN_KHAC, 0)) THANHTOAN_KHAC,
					sum(isnull(THANHTIEN_SI, 0)) THANHTIEN_SI, sum(isnull(THANHTIEN_LE, 0)) THANHTIEN_LE
				from	#impChungtuOnlineCT
				group by KHOA) a
   where	#impChungtuOnline.KHOA = a.KHOA

--Cấp SCT cho phiếu mới
begin
	declare @name nvarchar (250),
			@date	datetime

	declare tam cursor for
	select	 PHIEUGIAOHANG, NGAY
	  from	#impChungtuOnline
	 where	isnull(SCT, '') = ''
	order by NGAY

	open tam
	fetch next from tam into @name, @date

	while @@FETCH_STATUS = 0
	begin
		declare @SCT nvarchar(50)

		exec ALLOC_SCT @SCT out, @pLCT, @date	

		update	#impChungtuOnline
		  set	SCT = @SCT
		  where	PHIEUGIAOHANG = @name

		fetch next from tam into @name, @date
	end

	close tam
	deallocate tam
end

--================================eHoaDon========================================================
insert into #impeHoaDon
(
	TransNo,
	[KHOA], [PHIEUGIAOHANG],	[HoaDon_NguoiMua], [HoaDon_DonVi], [HoaDon_DiaChi], [HoaDon_DienThoai], [HoaDon_MaSoThue],
	[HoaDon_SoTaiKhoan], [HoaDon_HinhThucThanhToan], [HoaDon_Email], [KhoaPhieuGoc], [LctPhieuGoc], [SctPhieuGoc],
	[CREATE_BY], [UPDATE_BY], [CREATE_DATE], [UPDATE_DATE]
)
select distinct
	imp.TransNo,
	newID(), imp.[PHIEUGIAOHANG], imp.[HD_NMUA], imp.[HD_DONVI], imp.[HD_DCHI], imp.[HD_DTHOAI], imp.[HD_MST],
	imp.[HD_SOTK], imp.[HD_HTTT], imp.[HD_EMAIL], tmp.[KHOA], tmp.[LCT], tmp.[SCT],
	@UID ,@UID , @CREATE_DATE ,@CREATE_DATE         
  from	IMP_CHUNGTU_ONLINE imp join #impChungtuOnline tmp on imp.PHIEUGIAOHANG = tmp.PHIEUGIAOHANG
 where	isnull(imp.ErrCode, '') = '' 
		and imp.TransNo = @TRANSNO
		and tmp.HD_KHACHHANG = 1
group by imp.TransNo, imp.[PHIEUGIAOHANG],imp.[HD_NMUA], imp.[HD_DONVI], imp.[HD_DCHI], imp.[HD_DTHOAI], imp.[HD_MST],
	imp.[HD_SOTK], imp.[HD_HTTT], imp.[HD_EMAIL], tmp.[KHOA], tmp.[LCT], tmp.[SCT]

--cập nhật KHOA cho các hóa đơn đã có trong phần mềm
 update	c
  set	KhoaPhieuGoc = xuat.KHOA,
		KHOA = case when hd.KHOA is null then NEWID() else hd.KHOA end
 from	#impeHoaDon c join R_XUATHANG xuat on c.PHIEUGIAOHANG = xuat.PHIEUGIAOHANG 
				left join eHoaDon hd on xuat.KHOA = hd.KhoaPhieuGoc 
				where	xuat.LCT = @pLCT

--Cập nhật SCT cho eHoaDon
begin
	update #impeHoaDon
	set
		SctPhieuGoc = a.SCT
	from (select KHOA,SCT from #impChungtuOnline) a
	where #impeHoaDon.KhoaPhieuGoc = a.KHOA
end

select * from #impChungtuOnline
select * from #impChungtuOnlineCT
select * from #impeHoaDon
--Cập nhật các field vào Phiếu đã có trong phần mềm
--Master
Begin Transaction;
        Begin Try
			merge into XUATHANG as xuat
			using(
				select	*
				  from	#impChungtuOnline a 
				  )as dl ON xuat.KHOA = dl.KHOA
			when matched then
				update set
						[NGAY] = dl.NGAY,
						[MADT] = dl.MADT,
						[MADT2] = dl.[MADT2],
						[MAKHO] = dl.[MAKHO],
						[NGAY2] = dl.[NGAY2],
						[NGAY3] = dl.[NGAY3],

						SOLUONG = dl.SOLUONG,
						THANHTIEN = dl.THANHTIEN,
						SOTIEN_CKMH = dl.SOTIEN_CKMH,
						THANHTIEN_SAU_CKMH = dl.THANHTIEN_SAU_CKMH,
						SOTIEN_CKHD = dl.SOTIEN_CKHD,
						THANHTIEN_SAU_CKHD = dl.THANHTIEN_SAU_CKHD,
						THANHTIEN_CHUA_VAT_CL = dl.THANHTIEN_CHUA_VAT_CL,
						THANHTIEN_CL = dl.THANHTIEN_CL,
						THANHTIEN_CHUA_VAT = dl.THANHTIEN_CHUA_VAT,
						THANHTIEN_CHUA_VAT_5 = dl.THANHTIEN_CHUA_VAT_5,
						THANHTIEN_CHUA_VAT_8 = dl.THANHTIEN_CHUA_VAT_8,
						THANHTIEN_CHUA_VAT_10 = dl.THANHTIEN_CHUA_VAT_10,
						THANHTIEN_CHUA_VAT_KHAC = dl.THANHTIEN_CHUA_VAT_KHAC,
						TIEN_THUE_5 = dl.TIEN_THUE_5,
						TIEN_THUE_8 = dl.TIEN_THUE_8,
						TIEN_THUE_10 = dl.TIEN_THUE_10,
						TIEN_THUE_KHAC = dl.TIEN_THUE_KHAC,
						TIEN_THUE_CHUA_CL = dl.TIEN_THUE_CHUA_CL,
						TIEN_THUE_CL = dl.TIEN_THUE_CL,
						TIEN_THUE = dl.TIEN_THUE,
						THANHTOAN = dl.THANHTOAN,
						THANHTOAN_KCT = dl.THANHTOAN_KCT,
						THANHTOAN_0 = dl.THANHTOAN_0,
						THANHTOAN_5 = dl.THANHTOAN_5,
						THANHTOAN_8 = dl.THANHTOAN_8,
						THANHTOAN_10 = dl.THANHTOAN_10,
						THANHTOAN_KHAC = dl.THANHTOAN_KHAC,

						THANHTIEN_SI = dl.THANHTIEN_SI,
						THANHTIEN_LE = dl.THANHTIEN_LE,
	
						[HINHTHUC_GIA] = dl.[HINHTHUC_GIA],
						[LOAITHUE] = dl.LOAITHUE,
						[THUE_SUAT] = dl.THUE_SUAT,
						[UPDATE_BY] = dl.UPDATE_BY,
						[UPDATE_DATE] = dl.UPDATE_DATE,
			
						[SOVANDON] = dl.SOVANDON,
						[TINHTRANG] = dl.TINHTRANG,
						[TINHTRANG_GHICHU] = dl.TINHTRANG_GHICHU,
						[SAN_TAIKHOAN] = dl.[SAN_TAIKHOAN],
						[SAN_HOTEN] = dl.[SAN_HOTEN],
						[HD_KHACHHANG] = dl.[HD_KHACHHANG],

						[HD_NMUA] = dl.[HD_NMUA],
						[HD_DONVI] = dl.[HD_DONVI],
						[HD_DCHI] = dl.[HD_DCHI],
						[HD_DTHOAI] = dl.[HD_DTHOAI],
						[HD_EMAIL] = dl.[HD_EMAIL],
						[HD_HTTT] = dl.[HD_HTTT],
						[HD_MST] = dl.[HD_MST],
						[HD_SOTK] = dl.[HD_SOTK],
			
						[PHI_GIAMGIA] = dl.[PHI_GIAMGIA],
						[PHI_VANCHUYEN] = dl.[PHI_VANCHUYEN],
						[PHI_HOANXU] = dl.[PHI_HOANXU],
						[PHI_KHAC] = dl.[PHI_KHAC],
						[PHI_TONG] = dl.[PHI_TONG],
						[PHIVAT_TRAHANG] = dl.[PHIVAT_TRAHANG],
						[PHIVAT_CODINH] = dl.[PHIVAT_CODINH],
						[PHIVAT_DICHVU] = dl.[PHIVAT_DICHVU],
						[PHIVAT_THANHTOAN] = dl.[PHIVAT_THANHTOAN],
						[PHIVAT_SAN] = dl.[PHIVAT_SAN],
						[PHIVAT_QUANGCAO] = dl.[PHIVAT_QUANGCAO],
						[PHIVAT_SANCK] = dl.[PHIVAT_SANCK],
						[PHIVAT_HOAHONG] = dl.[PHIVAT_HOAHONG],
						[PHIVAT_PHAT] = dl.[PHIVAT_PHAT],
						[PHIVAT_KHAC] = dl.[PHIVAT_KHAC],
						[PHIVAT_TONG] = dl.[PHIVAT_TONG]
			
			when not matched then
				insert ([KHOA] ,[LCT] ,[NGAY] ,[SCT]
					   ,[MADT]
					   ,[MAKHO]
					   ,[SOLUONG]
					   ,[THANHTIEN]
					   ,[SOTIEN_CKMH]
					   ,[THANHTIEN_SAU_CKMH]
					   ,[SOTIEN_CKHD]
					   ,[THANHTIEN_SAU_CKHD]
					   ,[THANHTIEN_CHUA_VAT_CL]
					   ,[THANHTIEN_CL]
					   ,[THANHTIEN_CHUA_VAT]
					   ,[THANHTIEN_CHUA_VAT_5]
					   ,[THANHTIEN_CHUA_VAT_8]
					   ,[THANHTIEN_CHUA_VAT_10]
					   ,[THANHTIEN_CHUA_VAT_KHAC]
					   ,[TIEN_THUE_CHUA_CL]
					   ,[TIEN_THUE_CL]
					   ,[TIEN_THUE]
					   ,[TIEN_THUE_5]
					   ,[TIEN_THUE_8]
					   ,[TIEN_THUE_10]
					   ,[TIEN_THUE_KHAC]
					   ,[THANHTOAN]
					   ,[THANHTOAN_KCT]
					   ,[THANHTOAN_0]
					   ,[THANHTOAN_5]
					   ,[THANHTOAN_8]
					   ,[THANHTOAN_10]
					   ,[THANHTOAN_KHAC]
					   ,[THANHTIEN_SI]
					   ,[THANHTIEN_LE]
					   ,[HINHTHUC_GIA]
					   ,[LOAITHUE]
					   ,[THUE_SUAT]
					   ,[CREATE_BY]
					   ,[UPDATE_BY]
					   ,[CREATE_DATE]
					   ,[UPDATE_DATE]
					   ,[LOC]
					   ,[PHIEUGIAOHANG]
					   ,[SOVANDON]
					   ,[TINHTRANG]
					   ,[TINHTRANG_GHICHU]
					   ,[MADT2]
					   ,[NGAY2]
					   ,[NGAY3]
					   ,[SAN_TAIKHOAN]
					   ,[SAN_HOTEN]
					   ,[HD_KHACHHANG]

					   ,[HD_NMUA]
					   ,[HD_DONVI]
					   ,[HD_DCHI]
					   ,[HD_DTHOAI]
					   ,[HD_EMAIL]
					   ,[HD_HTTT]
					   ,[HD_MST]
					   ,[HD_SOTK]
					   ,[PHI_GIAMGIA]
					   ,[PHI_VANCHUYEN]
					   ,[PHI_HOANXU]
					   ,[PHI_KHAC]
					   ,[PHI_TONG]
					   ,[PHIVAT_TRAHANG]
					   ,[PHIVAT_CODINH]
					   ,[PHIVAT_DICHVU]
					   ,[PHIVAT_THANHTOAN]
					   ,[PHIVAT_SAN]
					   ,[PHIVAT_QUANGCAO]
					   ,[PHIVAT_SANCK]
					   ,[PHIVAT_HOAHONG]
					   ,[PHIVAT_PHAT]
					   ,[PHIVAT_KHAC]
					   ,[PHIVAT_TONG])
				values (dl.[KHOA] ,dl.[LCT] ,dl.[NGAY] ,dl.[SCT]
					   ,dl.[MADT]
					   ,dl.[MAKHO]
					   ,dl.[SOLUONG]
					   ,dl.[THANHTIEN]
					   ,dl.[SOTIEN_CKMH]
					   ,dl.[THANHTIEN_SAU_CKMH]
					   ,dl.[SOTIEN_CKHD]
					   ,dl.[THANHTIEN_SAU_CKHD]
					   ,dl.[THANHTIEN_CHUA_VAT_CL]
					   ,dl.[THANHTIEN_CL]
					   ,dl.[THANHTIEN_CHUA_VAT]
					   ,dl.[THANHTIEN_CHUA_VAT_5]
					   ,dl.[THANHTIEN_CHUA_VAT_8]
					   ,dl.[THANHTIEN_CHUA_VAT_10]
					   ,dl.[THANHTIEN_CHUA_VAT_KHAC]
					   ,dl.[TIEN_THUE_CHUA_CL]
					   ,dl.[TIEN_THUE_CL]
					   ,dl.[TIEN_THUE]
					   ,dl.[TIEN_THUE_5]
					   ,dl.[TIEN_THUE_8]
					   ,dl.[TIEN_THUE_10]
					   ,dl.[TIEN_THUE_KHAC]
					   ,dl.[THANHTOAN]
					   ,dl.[THANHTOAN_KCT]
					   ,dl.[THANHTOAN_0]
					   ,dl.[THANHTOAN_5]
					   ,dl.[THANHTOAN_8]
					   ,dl.[THANHTOAN_10]
					   ,dl.[THANHTOAN_KHAC]
					   ,dl.[THANHTIEN_SI]
					   ,dl.[THANHTIEN_LE]
					   ,dl.[HINHTHUC_GIA]
					   ,dl.[LOAITHUE]
					   ,dl.[THUE_SUAT]
					   ,dl.[CREATE_BY]
					   ,dl.[UPDATE_BY]
					   ,dl.[CREATE_DATE]
					   ,dl.[UPDATE_DATE]
					   ,dl.[LOC]
					   ,dl.[PHIEUGIAOHANG]
					   ,dl.[SOVANDON]
					   ,dl.[TINHTRANG]
					   ,dl.[TINHTRANG_GHICHU]
					   ,dl.[MADT2]
					   ,dl.[NGAY2]
					   ,dl.[NGAY3]
					   ,dl.[SAN_TAIKHOAN]
					   ,dl.[SAN_HOTEN]
					   ,dl.[HD_KHACHHANG]
					   ,dl.[HD_KHOA]
					   ,dl.[HD_NMUA]
					   ,dl.[HD_DONVI]
					   ,dl.[HD_DCHI]
					   ,dl.[HD_DTHOAI]
					   ,dl.[HD_EMAIL]
					   ,dl.[HD_HTTT]
					   ,dl.[HD_MST]
					   ,dl.[HD_SOTK]
					   ,dl.[PHI_GIAMGIA]
					   ,dl.[PHI_VANCHUYEN]
					   ,dl.[PHI_HOANXU]
					   ,dl.[PHI_KHAC]
					   ,dl.[PHI_TONG]
					   ,dl.[PHIVAT_TRAHANG]
					   ,dl.[PHIVAT_CODINH]
					   ,dl.[PHIVAT_DICHVU]
					   ,dl.[PHIVAT_THANHTOAN]
					   ,dl.[PHIVAT_SAN]
					   ,dl.[PHIVAT_QUANGCAO]
					   ,dl.[PHIVAT_SANCK]
					   ,dl.[PHIVAT_HOAHONG]
					   ,dl.[PHIVAT_PHAT]
					   ,dl.[PHIVAT_KHAC]
					   ,dl.[PHIVAT_TONG]
						)
			;
			
			--Detail
			merge into XUATHANG_CT as xuatct
			using(
				select	*
				  from	#impChungtuOnlineCT
				  )as dl ON xuatct.KHOACT = dl.KHOACT
			when matched then
				update set				
				  [KHOA] = dl.KHOA
				  ,[STT] = dl.STT
				  ,[MAVT] = dl.MAVT
				  ,[TENVT] = dl.TENVT
				  ,[DVT] = dl. DVT
				  ,[QD1] = dl.QD1
				  ,[DVT_BOX] = dl.DVT_BOX
				  ,[SOLUONG] = dl.SOLUONG
				  ,[SOLUONG_BOX] = dl.SOLUONG_BOX
				  ,[SOLUONG_BOX_LE] = dl.SOLUONG_BOX_LE
				  ,[DONGIA] = dl.DONGIA
				  ,[DONGIA_BOX] = dl.DONGIA_BOX
				  ,[TL_CKMH] = dl.TL_CKMH
				  ,[DONGIA_CKMH] = dl.DONGIA_CKMH
				  ,[DONGIA_BOX_CKMH] = dl.DONGIA_BOX_CKMH
				  ,[TL_CKHD] = dl.TL_CKHD
				  ,[DONGIA_CKHD] = dl.DONGIA_CKHD
				  ,[DONGIA_BOX_CKHD] = dl.DONGIA_BOX_CKHD
				  ,[DONGIA_CHUA_VAT] = dl.DONGIA_CHUA_VAT
				  ,[DONGIA_BOX_CHUA_VAT] = dl.DONGIA_BOX_CHUA_VAT
				  ,[BO] = dl.BO
				  ,[KHONG_TINHTON] = dl.KHONG_TINHTON
				  ,[DONGIA_SI] = dl.DONGIA_SI
				  ,[DONGIA_LE] = dl.DONGIA_LE,
      
	  					THANHTIEN = dl.THANHTIEN,
						SOTIEN_CKMH = dl.SOTIEN_CKMH,
						THANHTIEN_SAU_CKMH = dl.THANHTIEN_SAU_CKMH,
						SOTIEN_CKHD = dl.SOTIEN_CKHD,
						THANHTIEN_SAU_CKHD = dl.THANHTIEN_SAU_CKHD,
						THANHTIEN_CHUA_VAT_CL = dl.THANHTIEN_CHUA_VAT_CL,
						THANHTIEN_CL = dl.THANHTIEN_CL,
						THANHTIEN_CHUA_VAT = dl.THANHTIEN_CHUA_VAT,
						THANHTIEN_CHUA_VAT_5 = dl.THANHTIEN_CHUA_VAT_5,
						THANHTIEN_CHUA_VAT_8 = dl.THANHTIEN_CHUA_VAT_8,
						THANHTIEN_CHUA_VAT_10 = dl.THANHTIEN_CHUA_VAT_10,
						THANHTIEN_CHUA_VAT_KHAC = dl.THANHTIEN_CHUA_VAT_KHAC,
						TIEN_THUE_5 = dl.TIEN_THUE_5,
						TIEN_THUE_8 = dl.TIEN_THUE_8,
						TIEN_THUE_10 = dl.TIEN_THUE_10,
						TIEN_THUE_KHAC = dl.TIEN_THUE_KHAC,
						TIEN_THUE_CHUA_CL = dl.TIEN_THUE_CHUA_CL,
						TIEN_THUE_CL = dl.TIEN_THUE_CL,
						TIEN_THUE = dl.TIEN_THUE,
						THANHTOAN = dl.THANHTOAN,
						THANHTOAN_KCT = dl.THANHTOAN_KCT,
						THANHTOAN_0 = dl.THANHTOAN_0,
						THANHTOAN_5 = dl.THANHTOAN_5,
						THANHTOAN_8 = dl.THANHTOAN_8,
						THANHTOAN_10 = dl.THANHTOAN_10,
						THANHTOAN_KHAC = dl.THANHTOAN_KHAC,

						THANHTIEN_SI = dl.THANHTIEN_SI,
						THANHTIEN_LE = dl.THANHTIEN_LE,
	
						[LOAITHUE] = dl.LOAITHUE,
						[THUE_SUAT] = dl.THUE_SUAT,
			
						[PHI_GIAMGIA] = dl.[PHI_GIAMGIA],
						[PHI_VANCHUYEN] = dl.[PHI_VANCHUYEN],
						[PHI_HOANXU] = dl.[PHI_HOANXU],
						[PHI_KHAC] = dl.[PHI_KHAC],
						[PHI_TONG] = dl.[PHI_TONG],
						[PHIVAT_TRAHANG] = dl.[PHIVAT_TRAHANG],
						[PHIVAT_CODINH] = dl.[PHIVAT_CODINH],
						[PHIVAT_DICHVU] = dl.[PHIVAT_DICHVU],
						[PHIVAT_THANHTOAN] = dl.[PHIVAT_THANHTOAN],
						[PHIVAT_SAN] = dl.[PHIVAT_SAN],
						[PHIVAT_QUANGCAO] = dl.[PHIVAT_QUANGCAO],
						[PHIVAT_SANCK] = dl.[PHIVAT_SANCK],
						[PHIVAT_HOAHONG] = dl.[PHIVAT_HOAHONG],
						[PHIVAT_PHAT] = dl.[PHIVAT_PHAT],
						[PHIVAT_KHAC] = dl.[PHIVAT_KHAC],
						[PHIVAT_TONG] = dl.[PHIVAT_TONG]

			when not matched then
				insert (KHOACT, [KHOA], [STT]
				  ,[MAVT]
				  ,[TENVT]
				  ,[DVT]
				  ,[QD1]
				  ,[DVT_BOX]
				  ,[SOLUONG]
				  ,[SOLUONG_BOX]
				  ,[SOLUONG_BOX_LE]
				  ,[DONGIA]
				  ,[DONGIA_BOX]
				  ,[TL_CKMH]
				  ,[DONGIA_CKMH]
				  ,[DONGIA_BOX_CKMH]
				  ,[TL_CKHD]
				  ,[DONGIA_CKHD]
				  ,[DONGIA_BOX_CKHD]
				  ,[DONGIA_CHUA_VAT]
				  ,[DONGIA_BOX_CHUA_VAT]
				  ,[BO]
				  ,[KHONG_TINHTON]
				  ,[DONGIA_SI]
				  ,[DONGIA_LE]

					   ,[THANHTIEN]
					   ,[SOTIEN_CKMH]
					   ,[THANHTIEN_SAU_CKMH]
					   ,[SOTIEN_CKHD]
					   ,[THANHTIEN_SAU_CKHD]
					   ,[THANHTIEN_CHUA_VAT_CL]
					   ,[THANHTIEN_CL]
					   ,[THANHTIEN_CHUA_VAT]
					   ,[THANHTIEN_CHUA_VAT_5]
					   ,[THANHTIEN_CHUA_VAT_8]
					   ,[THANHTIEN_CHUA_VAT_10]
					   ,[THANHTIEN_CHUA_VAT_KHAC]
					   ,[TIEN_THUE_CHUA_CL]
					   ,[TIEN_THUE_CL]
					   ,[TIEN_THUE]
					   ,[TIEN_THUE_5]
					   ,[TIEN_THUE_8]
					   ,[TIEN_THUE_10]
					   ,[TIEN_THUE_KHAC]
					   ,[THANHTOAN]
					   ,[THANHTOAN_KCT]
					   ,[THANHTOAN_0]
					   ,[THANHTOAN_5]
					   ,[THANHTOAN_8]
					   ,[THANHTOAN_10]
					   ,[THANHTOAN_KHAC]
					   ,[THANHTIEN_SI]
					   ,[THANHTIEN_LE]
					   ,[LOAITHUE]
					   ,[THUE_SUAT]
					   ,[PHI_GIAMGIA]
					   ,[PHI_VANCHUYEN]
					   ,[PHI_HOANXU]
					   ,[PHI_KHAC]
					   ,[PHI_TONG]
					   ,[PHIVAT_TRAHANG]
					   ,[PHIVAT_CODINH]
					   ,[PHIVAT_DICHVU]
					   ,[PHIVAT_THANHTOAN]
					   ,[PHIVAT_SAN]
					   ,[PHIVAT_QUANGCAO]
					   ,[PHIVAT_SANCK]
					   ,[PHIVAT_HOAHONG]
					   ,[PHIVAT_PHAT]
					   ,[PHIVAT_KHAC]
					   ,[PHIVAT_TONG])
				values (dl.KHOACT, dl.[KHOA], dl.[STT]
					,dl.[MAVT]
					  ,dl.[TENVT]
					  ,dl.[DVT]
					  ,dl.[QD1]
					  ,dl.[DVT_BOX]
					  ,dl.[SOLUONG]
					  ,dl.[SOLUONG_BOX]
					  ,dl.[SOLUONG_BOX_LE]
					  ,dl.[DONGIA]
					  ,dl.[DONGIA_BOX]
					  ,dl.[TL_CKMH]
					  ,dl.[DONGIA_CKMH]
					  ,dl.[DONGIA_BOX_CKMH]
					  ,dl.[TL_CKHD]
					  ,dl.[DONGIA_CKHD]
					  ,dl.[DONGIA_BOX_CKHD]
					  ,dl.[DONGIA_CHUA_VAT]
					  ,dl.[DONGIA_BOX_CHUA_VAT]
					  ,dl.[BO]
					  ,dl.[KHONG_TINHTON]
					  ,dl.[DONGIA_SI]
					  ,dl.[DONGIA_LE]	

					   ,dl.[THANHTIEN]
					   ,dl.[SOTIEN_CKMH]
					   ,dl.[THANHTIEN_SAU_CKMH]
					   ,dl.[SOTIEN_CKHD]
					   ,dl.[THANHTIEN_SAU_CKHD]
					   ,dl.[THANHTIEN_CHUA_VAT_CL]
					   ,dl.[THANHTIEN_CL]
					   ,dl.[THANHTIEN_CHUA_VAT]
					   ,dl.[THANHTIEN_CHUA_VAT_5]
					   ,dl.[THANHTIEN_CHUA_VAT_8]
					   ,dl.[THANHTIEN_CHUA_VAT_10]
					   ,dl.[THANHTIEN_CHUA_VAT_KHAC]
					   ,dl.[TIEN_THUE_CHUA_CL]
					   ,dl.[TIEN_THUE_CL]
					   ,dl.[TIEN_THUE]
					   ,dl.[TIEN_THUE_5]
					   ,dl.[TIEN_THUE_8]
					   ,dl.[TIEN_THUE_10]
					   ,dl.[TIEN_THUE_KHAC]
					   ,dl.[THANHTOAN]
					   ,dl.[THANHTOAN_KCT]
					   ,dl.[THANHTOAN_0]
					   ,dl.[THANHTOAN_5]
					   ,dl.[THANHTOAN_8]
					   ,dl.[THANHTOAN_10]
					   ,dl.[THANHTOAN_KHAC]
					   ,dl.[THANHTIEN_SI]
					   ,dl.[THANHTIEN_LE]
					   ,dl.[LOAITHUE]
					   ,dl.[THUE_SUAT]
					   ,dl.[PHI_GIAMGIA]
					   ,dl.[PHI_VANCHUYEN]
					   ,dl.[PHI_HOANXU]
					   ,dl.[PHI_KHAC]
					   ,dl.[PHI_TONG]
					   ,dl.[PHIVAT_TRAHANG]
					   ,dl.[PHIVAT_CODINH]
					   ,dl.[PHIVAT_DICHVU]
					   ,dl.[PHIVAT_THANHTOAN]
					   ,dl.[PHIVAT_SAN]
					   ,dl.[PHIVAT_QUANGCAO]
					   ,dl.[PHIVAT_SANCK]
					   ,dl.[PHIVAT_HOAHONG]
					   ,dl.[PHIVAT_PHAT]
					   ,dl.[PHIVAT_KHAC]
					   ,dl.[PHIVAT_TONG])
			;
			--eHoaDon
			merge into eHoaDon as hd
			using(
				select	*
				  from	#impeHoaDon
				  )as dl ON hd.KHOA = dl.KHOA
			when matched then
				update set
				[DoiTacLienKet] = dl.[DoiTacLienKet], 
				[InvoiceStatusID] = dl.[InvoiceStatusID], 
				[InvoiceGUID] = dl.[InvoiceGUID], 
				[HoaDon_KyHieu] = dl.[HoaDon_KyHieu], 
				[HoaDon_So] = dl.[HoaDon_So], 
				[HoaDon_Mau] = dl.[HoaDon_Mau], 
				[HoaDon_Ngay] = dl.[HoaDon_Ngay], 
				[HoaDon_NguoiMua] = dl.[HoaDon_NguoiMua], 
				[HoaDon_DonVi] = dl.[HoaDon_DonVi], 
				[HoaDon_DiaChi] = dl.[HoaDon_DiaChi], 
				[HoaDon_DienThoai] = dl.[HoaDon_DienThoai],
				[HoaDon_MaSoThue] = dl.[HoaDon_MaSoThue], 
				[HoaDon_SoTaiKhoan] = dl.[HoaDon_SoTaiKhoan],
				[HoaDon_HinhThucThanhToan] = dl.[HoaDon_HinhThucThanhToan], 
				[HoaDon_MaTraCuu] = dl.[HoaDon_MaTraCuu], 
				[HoaDon_Email] = dl.[HoaDon_Email], 
				[HoaDon_LyDo] = dl.[HoaDon_LyDo], 
				[KhoaPhieuGoc] = dl.[KhoaPhieuGoc], 
				[LctPhieuGoc] = dl.[LctPhieuGoc], 
				[SctPhieuGoc] = dl.[SctPhieuGoc], 
				[NgayPhatHanh] = dl.[NgayPhatHanh], 
				[MaCuaCQT] = dl.[MaCuaCQT],
				[CREATE_BY] = dl.[CREATE_BY],
				[UPDATE_BY] = dl.[UPDATE_BY],
				[DELETE_BY] = dl.[DELETE_BY],
				[CREATE_DATE] = dl.[CREATE_DATE], 
				[UPDATE_DATE] = dl.[UPDATE_DATE], 
				[DELETE_DATE] = dl.[DELETE_DATE]
			when not matched then
				insert ([KHOA]
					,[DoiTacLienKet]
					,[InvoiceStatusID]
					,[InvoiceGUID]
					,[HoaDon_KyHieu]
					,[HoaDon_So]
					,[HoaDon_Mau]
					,[HoaDon_Ngay]
					,[HoaDon_NguoiMua]
					,[HoaDon_DonVi]
					,[HoaDon_DiaChi]
					,[HoaDon_DienThoai]
					,[HoaDon_MaSoThue]
					,[HoaDon_SoTaiKhoan]
					,[HoaDon_HinhThucThanhToan]
					,[HoaDon_MaTraCuu]
					,[HoaDon_Email]
					,[HoaDon_LyDo]
					,[KhoaPhieuGoc]
					,[LctPhieuGoc]
					,[SctPhieuGoc]
					,[NgayPhatHanh]
					,[MaCuaCQT]
					,[CREATE_BY]
					,[UPDATE_BY]
					,[DELETE_BY]
					,[CREATE_DATE]
					,[UPDATE_DATE]
					,[DELETE_DATE])
				values (dl.[KHOA]
					  ,dl.[DoiTacLienKet]
					  ,dl.[InvoiceStatusID]
					  ,dl.[InvoiceGUID]
					  ,dl.[HoaDon_KyHieu]
					  ,dl.[HoaDon_So]
					  ,dl.[HoaDon_Mau]
					  ,dl.[HoaDon_Ngay]
					  ,dl.[HoaDon_NguoiMua]
					  ,dl.[HoaDon_DonVi]
					  ,dl.[HoaDon_DiaChi]
					  ,dl.[HoaDon_DienThoai]
					  ,dl.[HoaDon_MaSoThue]
					  ,dl.[HoaDon_SoTaiKhoan]
					  ,dl.[HoaDon_HinhThucThanhToan]
					  ,dl.[HoaDon_MaTraCuu]
					  ,dl.[HoaDon_Email]
					  ,dl.[HoaDon_LyDo]
					  ,dl.[KhoaPhieuGoc]
					  ,dl.[LctPhieuGoc]
					  ,dl.[SctPhieuGoc]
					  ,dl.[NgayPhatHanh]
					  ,dl.[MaCuaCQT]
					  ,dl.[CREATE_BY]
					  ,dl.[UPDATE_BY]
					  ,dl.[DELETE_BY]
					  ,dl.[CREATE_DATE]
					  ,dl.[UPDATE_DATE]
					  ,dl.[DELETE_DATE]);
--AfterPostPhieu: Cập nhật Chi tiết bộ
		begin
			declare @KHOA uniqueidentifier

			declare tam2 cursor for
			select	 KHOA
				from	#impChungtuOnline
			order by NGAY

			open tam2
			fetch next from tam2 into @KHOA

			while @@FETCH_STATUS = 0
			begin
				exec spAfterPostPhieu_XUATHANG @KHOA, @pLCT
				fetch next from tam2 into @KHOA
			end
			
			close tam2
			deallocate tam2
		end
-- COMMIT
        Commit Transaction;            
            select @RET = count(*)
			from #impChungtuOnlineCT 
				
		End Try
		Begin Catch
			RollBack Transaction;
			--------------------------------------------
			close tam2
			deallocate tam2

			Declare
				@ErrorCode As Int = Error_Number();
			Declare
				@ErrorMessage As NVarchar(500) = Error_Message();
			Declare
				@StackTrace As VarChar(200) = Db_Name() + '.' + Schema_Name() + '.' + Error_Procedure();
			
			update IMP_CHUNGTU_ONLINE set ErrCode = @ErrorMessage + '_' + @StackTrace where isnull(ErrCode, '') = ''
			--------------------------------------------
			Select
				-1;
		End Catch;

select KHOACT, count(*) from #impChungtuOnlineCT
group by KHOACT
having count(*) > 1

drop table #impChungtuOnline
drop table #impChungtuOnlineCT

delete IMP_CHUNGTU_ONLINE
where isnull(ErrCode, '') = ''

RETURN @RET
END
