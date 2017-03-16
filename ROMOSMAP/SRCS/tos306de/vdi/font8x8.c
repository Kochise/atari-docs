/*
 ******************* Revision Control System *****************************
 *
 * $Author: lozben $
 * =======================================================================
 *
 * $Date: 91/01/03 15:09:14 $
 * =======================================================================
 *
 * Revision 3.0  91/01/03  15:09:14  lozben
 * New generation VDI
 * 
 * Revision 2.1  89/02/21  17:20:51  kbad
 * *** TOS 1.4  FINAL RELEASE VERSION ***
 * 
 * Revision 1.1  87/11/20  15:15:17  lozben
 * Initial revision
 * 
 * =======================================================================
 *
 *************************************************************************
 */

#include "vdi.h"
#include "fontdef.h"
#include "gsxextrn.h"
#include "ctrycodes.h"


extern int16_t const off_8x8[];
extern int16_t const dat_8x8[];


struct font_head const f8x8 = {

    1,					/*   int16_t  font_id		*/
    9,					/*   int16_t  point	 	*/
   "8x8 system font",			/*   char  name[32]	 	*/
    0,					/*   uint16_t first_ade	 	*/
    255,				/*   uint16_t last_ade	 	*/
    6,					/*   uint16_t top		 	*/
    6,					/*   uint16_t ascent	 	*/
    4,					/*   uint16_t half			*/
    1,					/*   uint16_t descent		*/
    1,					/*   uint16_t bottom	 	*/
    7,					/*   uint16_t max_char_width	*/
    8,					/*   uint16_t max_cell_width	*/
    1,					/*   uint16_t left_offset		*/
    3,					/*   uint16_t right_offset		*/
    1,					/*   uint16_t thicken		*/
    1,					/*   uint16_t ul_size		*/
    0x5555,				/*   uint16_t lighten		*/
    0x5555,				/*   uint16_t skew			*/
#if TOSVERSION >= 0x400
    STDFORM | MONOSPACE,/*   uint16_t flags		*/
#else
    STDFORM | MONOSPACE | DEFAULT,/*   uint16_t flags		*/
#endif
    0,					/*   uint8_t *hor_table		*/
    (const uint16_t *)off_8x8,			/*   uint16_t *off_table		*/
    (const uint16_t *)dat_8x8,			/*   uint16_t *dat_table		*/
    256,				/*   uint16_t form_width		*/
    8,					/*   uint16_t form_height		*/
    &ram8x16,			/*   uint16_t *next_font		*/
    0					/*   uint16_t next_seg		*/

};


int16_t const off_8x8[257] =
{
	0x0000,0x0008,0x0010,0x0018,0x0020,0x0028,0x0030,0x0038,
	0x0040,0x0048,0x0050,0x0058,0x0060,0x0068,0x0070,0x0078,
	0x0080,0x0088,0x0090,0x0098,0x00A0,0x00A8,0x00B0,0x00B8,
	0x00C0,0x00C8,0x00D0,0x00D8,0x00E0,0x00E8,0x00F0,0x00F8,
	0x0100,0x0108,0x0110,0x0118,0x0120,0x0128,0x0130,0x0138,
	0x0140,0x0148,0x0150,0x0158,0x0160,0x0168,0x0170,0x0178,
	0x0180,0x0188,0x0190,0x0198,0x01A0,0x01A8,0x01B0,0x01B8,
	0x01C0,0x01C8,0x01D0,0x01D8,0x01E0,0x01E8,0x01F0,0x01F8,
	0x0200,0x0208,0x0210,0x0218,0x0220,0x0228,0x0230,0x0238,
	0x0240,0x0248,0x0250,0x0258,0x0260,0x0268,0x0270,0x0278,
	0x0280,0x0288,0x0290,0x0298,0x02A0,0x02A8,0x02B0,0x02B8,
	0x02C0,0x02C8,0x02D0,0x02D8,0x02E0,0x02E8,0x02F0,0x02F8,
	0x0300,0x0308,0x0310,0x0318,0x0320,0x0328,0x0330,0x0338,
	0x0340,0x0348,0x0350,0x0358,0x0360,0x0368,0x0370,0x0378,
	0x0380,0x0388,0x0390,0x0398,0x03A0,0x03A8,0x03B0,0x03B8,
	0x03C0,0x03C8,0x03D0,0x03D8,0x03E0,0x03E8,0x03F0,0x03F8,
	0x0400,0x0408,0x0410,0x0418,0x0420,0x0428,0x0430,0x0438,
	0x0440,0x0448,0x0450,0x0458,0x0460,0x0468,0x0470,0x0478,
	0x0480,0x0488,0x0490,0x0498,0x04A0,0x04A8,0x04B0,0x04B8,
	0x04C0,0x04C8,0x04D0,0x04D8,0x04E0,0x04E8,0x04F0,0x04F8,
	0x0500,0x0508,0x0510,0x0518,0x0520,0x0528,0x0530,0x0538,
	0x0540,0x0548,0x0550,0x0558,0x0560,0x0568,0x0570,0x0578,
	0x0580,0x0588,0x0590,0x0598,0x05A0,0x05A8,0x05B0,0x05B8,
	0x05C0,0x05C8,0x05D0,0x05D8,0x05E0,0x05E8,0x05F0,0x05F8,
	0x0600,0x0608,0x0610,0x0618,0x0620,0x0628,0x0630,0x0638,
	0x0640,0x0648,0x0650,0x0658,0x0660,0x0668,0x0670,0x0678,
	0x0680,0x0688,0x0690,0x0698,0x06A0,0x06A8,0x06B0,0x06B8,
	0x06C0,0x06C8,0x06D0,0x06D8,0x06E0,0x06E8,0x06F0,0x06F8,
	0x0700,0x0708,0x0710,0x0718,0x0720,0x0728,0x0730,0x0738,
	0x0740,0x0748,0x0750,0x0758,0x0760,0x0768,0x0770,0x0778,
	0x0780,0x0788,0x0790,0x0798,0x07A0,0x07A8,0x07B0,0x07B8,
	0x07C0,0x07C8,0x07D0,0x07D8,0x07E0,0x07E8,0x07F0,0x07F8,
	0x0800
};


int16_t const dat_8x8[1024] =
{
#if OS_COUNTRY == CTRY_PL
	/* apparently a patch that was applied by the maker of the PL version */
	0x0018,0x3C18,0x183C,0xFFE7,0x017E,0x1818,0xF0F0,0x05A0,
	0x7C06,0x7C7C,0xC67C,0x7C7C,0x7C7C,0x0078,0x07F0,0x1104,
	0x0018,0x6600,0x1800,0x3818,0x0E70,0x0000,0x0000,0x0002,
	0x3C18,0x3C7E,0x0C7E,0x3C7E,0x3C3C,0x0000,0x0600,0x603C,
	0x3C18,0x7C3C,0x787E,0x7E3E,0x663C,0x0666,0x60C6,0x663C,
	0x7C3C,0x7C3C,0x7E66,0x66C6,0x6666,0x7E1E,0x4078,0x1000,
	0x0000,0x6000,0x0600,0x1C00,0x6018,0x1860,0x3800,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x000E,0x1870,0x0000,
	0x0000,0x6666,0x6666,0x6666,0x6666,0x1818,0x300C,0x3030,
	0x1818,0x1866,0x0000,0x6666,0x0066,0x6618,0x1C18,0x6618,
	0x0018,0x1800,0x1800,0x1818,0x6666,0x0066,0x0066,0x0066,
	0x1866,0x0000,0x6618,0x0000,0x6618,0x1800,0x7AAA,0xA8AA,
	0x0E18,0x187E,0x6018,0x1818,0x187E,0x00FF,0x00F0,0x0FFF,
	0x0000,0x0C00,0x380C,0x0C0C,0x0C18,0xC6C6,0x1BD8,0x0000,
	0x001C,0x0000,0xFE00,0x0000,0x3C00,0x001C,0x6600,0x3E3C,
	0x0018,0x300C,0x0018,0x1800,0x3800,0x0000,0x3838,0x0000,
	0x003C,0x241C,0x3899,0xFFC3,0x03C3,0x3C1C,0xC0C0,0x05A0,
	0xC606,0x0606,0xC6C0,0xC006,0xC6C6,0x0060,0x0FF8,0x0B28,
	0x0018,0x666C,0x3E66,0x6C18,0x1C38,0x6618,0x0000,0x0006,
	0x6638,0x660C,0x1C60,0x6006,0x6666,0x1818,0x0C00,0x3066,
	0x663C,0x6666,0x6C60,0x6060,0x6618,0x066C,0x60EE,0x7666,
	0x6666,0x6666,0x1866,0x66C6,0x6666,0x0618,0x6018,0x3800,
	0xC000,0x6000,0x0600,0x3000,0x6000,0x0060,0x1800,0x0000,
	0x0000,0x0000,0x1800,0x0000,0x0000,0x0018,0x1818,0x6018,
	0x3C00,0x0000,0x0000,0x0000,0x0000,0x6666,0x1818,0x1818,
	0x1818,0x1866,0x0000,0x6666,0x0066,0x6618,0x3A18,0x6666,
	0x0018,0x1800,0x1800,0x1818,0x6666,0x0066,0x0066,0x0066,
	0x1866,0x0000,0x6618,0x0000,0x6618,0x1800,0xCA00,0x5055,
	0x1B3C,0x3C60,0x6066,0x3C3C,0x7E06,0x18FF,0x00F0,0x0FFF,
	0x1800,0x1800,0x1818,0x1818,0x1800,0xCCCC,0x366C,0x0000,
	0x0036,0xFE00,0x661E,0x0000,0x183C,0x3C36,0xF710,0x7066,
	0x7E18,0x1818,0x0E18,0x1832,0x6C00,0x0000,0x6C6C,0x3C00,
	0x0066,0x24F6,0x6FC3,0xFE99,0x06D3,0x3C16,0xFEDF,0x05A0,
	0xC606,0x0606,0xC6C0,0xC006,0xC6C6,0x3C78,0x1FEC,0x0DD8,
	0x0018,0x66FE,0x606C,0x3818,0x1818,0x3C18,0x0000,0x000C,
	0x6E18,0x0618,0x3C7C,0x600C,0x6666,0x1818,0x187E,0x1806,
	0x6E66,0x6660,0x6660,0x6060,0x6618,0x0678,0x60FE,0x7E66,
	0x6666,0x6660,0x1866,0x66C6,0x3C66,0x0C18,0x3018,0x6C00,
	0x603C,0x7C3C,0x3E3C,0x7C3E,0x7C38,0x1866,0x18EC,0x7C3C,
	0x7C3E,0x7C3E,0x7E66,0x66C6,0x6666,0x7E18,0x1818,0xF218,
	0x663C,0x6600,0x183C,0x3C00,0x3C00,0x3C00,0x3C3C,0x3C00,
	0x1818,0xF866,0x00F8,0xE666,0xFEE6,0x66F8,0x303C,0x3C3C,
	0x0018,0x1800,0x1800,0x181F,0x6667,0x7FE7,0xFF67,0xFFE7,
	0xFF66,0xFF00,0x661F,0x1F00,0x66FF,0x1800,0xCAAA,0xA8AA,
	0x3C66,0x6660,0x6876,0x6660,0x2C0C,0x00FF,0x00F0,0x0FFF,
	0x003C,0x3C3C,0x1C7C,0x3C3E,0x7E7E,0xD8D8,0x6C36,0x0000,
	0x7666,0x66FE,0x3038,0x6C7E,0x3C66,0x6678,0x997C,0x6066,
	0x007E,0x0C30,0x1B18,0x004C,0x3838,0x000F,0x6C18,0x3C00,
	0x00C3,0xE783,0xC1E7,0xFC3C,0x8CD3,0x3C10,0xD8DB,0x0DB0,
	0x0000,0x7C7C,0x7C7C,0x7C00,0x7C7C,0x0660,0x1804,0x0628,
	0x0018,0x006C,0x3C18,0x7000,0x1818,0xFF7E,0x007E,0x0018,
	0x7618,0x0C0C,0x6C06,0x7C18,0x3C3E,0x0000,0x3000,0x0C0C,
	0x6A66,0x7C60,0x667C,0x7C6E,0x7E18,0x0670,0x60D6,0x7E66,
	0x7C66,0x7C3C,0x1866,0x66D6,0x183C,0x1818,0x1818,0xC600,
	0x3006,0x6660,0x6666,0x3066,0x6618,0x186C,0x18FE,0x6666,
	0x6666,0x6660,0x1866,0x66C6,0x3C66,0x0C30,0x180C,0x9E34,
	0x6060,0x6666,0x3C06,0x663C,0x6638,0x0638,0x6666,0x0666,
	0x18F8,0x18E6,0xFE18,0x0666,0x0606,0xFE18,0x7C60,0x1866,
	0xF81F,0xFFFF,0x1FFF,0xFF18,0x6760,0x6000,0x0060,0x0000,
	0x00FF,0x00FF,0x7F18,0x187F,0xFF18,0xF81F,0xCA00,0x5055,
	0x6666,0x607C,0x707E,0x663C,0x187E,0x18FF,0x00F0,0x0FFF,
	0x1806,0x6066,0x1866,0x6660,0x0C0C,0x3636,0xD81B,0x3E7C,
	0xDC7C,0x626C,0x186C,0x6C18,0x667E,0x66DC,0x99D6,0x7E66,
	0x7E18,0x1818,0x1B18,0x7E00,0x0038,0x0018,0x6C30,0x3C00,
	0x00E7,0xC383,0xC1C3,0xF999,0xD8DB,0x7E10,0xDEFF,0x0DB0,
	0xC606,0xC006,0x0606,0xC606,0xC606,0x7E7E,0x1804,0x07D0,
	0x0018,0x006C,0x0630,0xDE00,0x1818,0x3C18,0x0000,0x0030,
	0x6618,0x1806,0x7E06,0x6630,0x6606,0x1818,0x1800,0x1818,
	0x6E7E,0x6660,0x6660,0x6066,0x6618,0x0678,0x60C6,0x6E66,
	0x6076,0x6C06,0x1866,0x66FE,0x3C18,0x3018,0x0C18,0x0000,
	0x003E,0x6660,0x667E,0x3066,0x6618,0x1878,0x18D6,0x6666,
	0x6666,0x603C,0x1866,0x66D6,0x1866,0x1818,0x1818,0x0C34,
	0x6660,0x6666,0x663E,0x6666,0x7E18,0x3E18,0x7E7E,0x3E66,
	0x1818,0xF866,0x66F8,0xE666,0xE6FE,0x00F8,0x3060,0x3C7E,
	0x1800,0x0018,0x1800,0x181F,0x667F,0x67FF,0xE767,0xFFE7,
	0xFF00,0xFF66,0x001F,0x1F66,0x66FF,0x0018,0x7AAA,0xA8AA,
	0x667E,0x6060,0x607E,0x6606,0x3030,0x30FF,0xFFF0,0x0F00,
	0x183E,0x607E,0x3866,0x663C,0x1818,0x6B6E,0x6C36,0x300C,
	0xC866,0x606C,0x306C,0x6C18,0x6666,0x66CC,0xEFD6,0x6066,
	0x0018,0x300C,0x18D8,0x0032,0x0038,0x7ED8,0x6C7C,0x0000,
	0x0024,0x66F6,0x6F99,0xF3C3,0x70C3,0x1070,0x181E,0x1998,
	0xC606,0xC006,0x0606,0xC606,0xC606,0x6618,0x1004,0x2E10,
	0x0000,0x00FE,0x7C66,0xCC00,0x1C38,0x6618,0x3000,0x1860,
	0x6618,0x3066,0x0C66,0x6630,0x660C,0x1818,0x0C7E,0x3000,
	0x6066,0x6666,0x6C60,0x6066,0x6618,0x666C,0x60C6,0x6666,
	0x606C,0x6666,0x1866,0x3CEE,0x6618,0x6018,0x0618,0x0000,
	0x0066,0x6660,0x6660,0x303E,0x6618,0x186C,0x18C6,0x6666,
	0x6666,0x6006,0x1866,0x3C7C,0x3C3E,0x3018,0x1818,0x0062,
	0x3C3C,0x6666,0x7E66,0x6666,0x6018,0x6618,0x6060,0x6666,
	0x1818,0x1866,0x6618,0x6666,0x6600,0x0000,0x303C,0x1860,
	0x1800,0x0018,0x1800,0x1818,0x6600,0x6600,0x6666,0x0066,
	0x0000,0x1866,0x0000,0x1866,0x6618,0x0018,0x0A00,0x5055,
	0x3C66,0x6660,0xE06E,0x6666,0x6060,0x60FF,0xFFF0,0x0F00,
	0x1866,0x6060,0x1866,0x6606,0x3030,0xC3D6,0x366C,0x300C,
	0xDC66,0x606C,0x666C,0x6C18,0x3C66,0x24EC,0x66D6,0x7066,
	0x7E00,0x0000,0x18D8,0x184C,0x0000,0x0070,0x0000,0x0000,
	0x0024,0x3C1C,0x383C,0xE7E7,0x20C3,0x38F0,0x181B,0x799E,
	0x7C06,0x7C7C,0x067C,0x7C06,0x7C7C,0x3C1E,0x1E3C,0x39E0,
	0x0018,0x006C,0x1846,0x7600,0x0E70,0x0000,0x3000,0x1840,
	0x3C7E,0x7E3C,0x0C3C,0x3C30,0x3C38,0x0030,0x0600,0x6018,
	0x3E66,0x7C3C,0x787E,0x603E,0x663C,0x3C66,0x7EC6,0x663C,
	0x6036,0x663C,0x183E,0x18C6,0x6618,0x7E1E,0x0278,0x00FE,
	0x003E,0x7C3C,0x3E3C,0x3006,0x663C,0x1866,0x3CC6,0x663C,
	0x7C3E,0x607C,0x0E3E,0x186C,0x6606,0x7E0E,0x1870,0x007E,
	0x0808,0x3E3E,0x663E,0x3C3C,0x3C3C,0x3E3C,0x3C3C,0x3E3E,
	0x1818,0x1866,0x6618,0x6666,0x6600,0x0000,0x7E18,0x183C,
	0x1800,0x0018,0x1800,0x1818,0x6600,0x6600,0x6666,0x0066,
	0x0000,0x1866,0x0000,0x1866,0x6618,0x0018,0x0AAA,0xA8AA,
	0xD866,0x3C7E,0x7E66,0x3C3C,0x7E7E,0x66FF,0xFFF0,0x0F00,
	0x183E,0x3C3C,0x3C66,0x3C7C,0x7E7E,0x869F,0x1BD8,0x300C,
	0x767C,0x606C,0xFE38,0x7F18,0x183C,0x6678,0x007C,0x3E66,
	0x007E,0x7E7E,0x1870,0x1800,0x0000,0x0030,0x0000,0x0000,
	0x003C,0x1818,0x1800,0x0000,0x007E,0x1060,0x0000,0x718E,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x1754,0x3800,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x6000,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0000,0x0000,0x007C,0x0000,0x7000,0x0000,0x0000,
	0x6006,0x0000,0x0000,0x0000,0x007C,0x0000,0x1800,0x0000,
	0x3818,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x1818,0x1866,0x6618,0x6666,0x6600,0x0000,0x0018,0x0000,
	0x1800,0x0018,0x1800,0x1818,0x6600,0x6600,0x6666,0x0066,
	0x0000,0x1866,0x0000,0x1866,0x6618,0x0018,0x0A00,0x5055,
	0x700C,0x000C,0x0000,0x0000,0x0000,0x3CFF,0xFFF0,0x0F00,
	0x180C,0x000C,0x0000,0x0000,0x0000,0x0F06,0x0000,0x0000,
	0x0060,0xF848,0x0000,0xC010,0x3C00,0x0000,0x0010,0x0000,
	0x0000,0x0000,0x1800,0x0000,0x0000,0x0000,0x0000,0x0000
#else
	0x0018,0x3C18,0x183C,0xFFE7,0x017E,0x1818,0xF0F0,0x05A0,
	0x7C06,0x7C7C,0xC67C,0x7C7C,0x7C7C,0x0078,0x07F0,0x1104,
	0x0018,0x6600,0x1800,0x3818,0x0E70,0x0000,0x0000,0x0002,
	0x3C18,0x3C7E,0x0C7E,0x3C7E,0x3C3C,0x0000,0x0600,0x603C,
	0x3C18,0x7C3C,0x787E,0x7E3E,0x663C,0x0666,0x60C6,0x663C,
	0x7C3C,0x7C3C,0x7E66,0x66C6,0x6666,0x7E1E,0x4078,0x1000,
	0x0000,0x6000,0x0600,0x1C00,0x6018,0x1860,0x3800,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x000E,0x1870,0x0000,
	0x0066,0x0C18,0x6630,0x1800,0x1866,0x3066,0x1860,0x6618,
	0x0C00,0x3F18,0x6630,0x1830,0x6666,0x6618,0x1C66,0x1C1E,
	0x0C0C,0x0C0C,0x3434,0x0000,0x0000,0x00C6,0xC600,0x1BD8,
	0x3434,0x0200,0x007F,0x3034,0x3466,0x0C00,0x7A7E,0x7EF1,
	0x66F6,0x0000,0x0000,0x0000,0x0000,0x6000,0x0060,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x000E,0x0066,
	0x001C,0x0000,0xFE00,0x0000,0x3C00,0x001C,0x0C00,0x3E3C,
	0x0018,0x300C,0x0018,0x1800,0x3838,0x0000,0x3838,0x7800,
	0x003C,0x241C,0x3899,0xFFC3,0x03C3,0x3C1C,0xC0C0,0x05A0,
	0xC606,0x0606,0xC6C0,0xC006,0xC6C6,0x0060,0x0FF8,0x0B28,
	0x0018,0x666C,0x3E66,0x6C18,0x1C38,0x6618,0x0000,0x0006,
	0x6638,0x660C,0x1C60,0x6006,0x6666,0x1818,0x0C00,0x3066,
	0x663C,0x6666,0x6C60,0x6060,0x6618,0x066C,0x60EE,0x7666,
	0x6666,0x6666,0x1866,0x66C6,0x6666,0x0618,0x6018,0x3800,
	0xC000,0x6000,0x0600,0x3000,0x6000,0x0060,0x1800,0x0000,
	0x0000,0x0000,0x1800,0x0000,0x0000,0x0018,0x1818,0x6018,
	0x3C00,0x1866,0x0018,0x1800,0x6600,0x1800,0x6630,0x0000,
	0x1800,0x7866,0x0018,0x6618,0x0000,0x0018,0x3A66,0x3630,
	0x1818,0x1818,0x5858,0x3C3C,0x1800,0x00CC,0xCC18,0x366C,
	0x5858,0x3C02,0x00D8,0x1858,0x5800,0x1810,0xCAC3,0xC35B,
	0x0066,0x667C,0x1E7E,0x7C1C,0x1E7E,0x6E3C,0x3E7E,0x6C1C,
	0x3E36,0x7E66,0x3E78,0xD67C,0x1C3E,0xFE7E,0x361B,0x10F7,
	0x0036,0xFE00,0x661E,0x0000,0x183C,0x3C36,0x1810,0x7066,
	0x7E18,0x1818,0x0E18,0x1832,0x6C7C,0x0000,0x6C6C,0x0CFE,
	0x0066,0x24F6,0x6FC3,0xFE99,0x06D3,0x3C16,0xFEDF,0x05A0,
	0xC606,0x0606,0xC6C0,0xC006,0xC6C6,0x3C78,0x1FEC,0x0DD8,
	0x0018,0x66FE,0x606C,0x3818,0x1818,0x3C18,0x0000,0x000C,
	0x6E18,0x0618,0x3C7C,0x600C,0x6666,0x1818,0x187E,0x1806,
	0x6E66,0x6660,0x6660,0x6060,0x6618,0x0678,0x60FE,0x7E66,
	0x6666,0x6660,0x1866,0x66C6,0x3C66,0x0C18,0x3018,0x6C00,
	0x603C,0x7C3C,0x3E3C,0x7C3E,0x7C38,0x1866,0x18EC,0x7C3C,
	0x7C3E,0x7C3E,0x7E66,0x66C6,0x6666,0x7E18,0x1818,0xF218,
	0x6600,0x0000,0x3C00,0x003C,0x003C,0x0000,0x0000,0x1818,
	0x7E7E,0xD800,0x0000,0x0000,0x663C,0x663C,0x303C,0x667C,
	0x0000,0x0000,0x0000,0x0666,0x0000,0x00D8,0xD800,0x6C36,
	0x0000,0x663C,0x7ED8,0x0000,0x3C00,0x3038,0xCABD,0xBD5F,
	0xE666,0x760C,0x060C,0x060C,0x0C36,0x660C,0x0606,0x3E0C,
	0x3636,0x6666,0x060C,0xD66C,0x0C06,0x6666,0x363C,0x3899,
	0x7666,0x66FE,0x3038,0x6C7E,0x3C66,0x6678,0x387C,0x6066,
	0x007E,0x0C30,0x1B18,0x004C,0x3838,0x000F,0x6C18,0x3800,
	0x00C3,0xE783,0xC1E7,0xFC3C,0x8CD3,0x3C10,0xD8DB,0x0DB0,
	0x0000,0x7C7C,0x7C7C,0x7C00,0x7C7C,0x0660,0x1804,0x0628,
	0x0018,0x006C,0x3C18,0x7000,0x1818,0xFF7E,0x007E,0x0018,
	0x7618,0x0C0C,0x6C06,0x7C18,0x3C3E,0x0000,0x3000,0x0C0C,
	0x6A66,0x7C60,0x667C,0x7C6E,0x7E18,0x0670,0x60D6,0x7E66,
	0x7C66,0x7C3C,0x1866,0x66D6,0x183C,0x1818,0x1818,0xC600,
	0x3006,0x6660,0x6666,0x3066,0x6618,0x186C,0x18FE,0x6666,
	0x6666,0x6660,0x1866,0x66C6,0x3C66,0x0C30,0x180C,0x9E34,
	0x6066,0x3C3C,0x063C,0x3C60,0x3C66,0x3C38,0x3838,0x3C3C,
	0x601B,0xDE3C,0x3C3C,0x6666,0x6666,0x6660,0x7C18,0x7C30,
	0x3C38,0x3C66,0x7C66,0x3E66,0x183E,0x7C36,0x3618,0xD81B,
	0x3C3C,0x6E6E,0xDBDE,0x1818,0x6600,0x0010,0xCAB1,0xA555,
	0x6666,0x3C0C,0x0E0C,0x660C,0x0636,0x660C,0x0606,0x660C,
	0x3636,0x763C,0x360C,0xD66C,0x0C06,0x6676,0x1C66,0x6C99,
	0xDC7C,0x626C,0x186C,0x6C18,0x667E,0x66DC,0x54D6,0x7E66,
	0x7E18,0x1818,0x1B18,0x7E00,0x0000,0x0018,0x6C30,0x0C00,
	0x00E7,0xC383,0xC1C3,0xF999,0xD8DB,0x7E10,0xDEFF,0x0DB0,
	0xC606,0xC006,0x0606,0xC606,0xC606,0x7E7E,0x1804,0x07D0,
	0x0018,0x006C,0x0630,0xDE00,0x1818,0x3C18,0x0000,0x0030,
	0x6618,0x1806,0x7E06,0x6630,0x6606,0x1818,0x1800,0x1818,
	0x6E7E,0x6660,0x6660,0x6066,0x6618,0x0678,0x60C6,0x6E66,
	0x6076,0x6C06,0x1866,0x66FE,0x3C18,0x3018,0x0C18,0x0000,
	0x003E,0x6660,0x667E,0x3066,0x6618,0x1878,0x18D6,0x6666,
	0x6666,0x603C,0x1866,0x66D6,0x1866,0x1818,0x1818,0x0C34,
	0x6666,0x7E06,0x3E06,0x0660,0x7E7E,0x7E18,0x1818,0x6666,
	0x7C7F,0xF866,0x6666,0x6666,0x6666,0x6660,0x303C,0x6630,
	0x0618,0x6666,0x6676,0x6666,0x3030,0x0C6B,0x6E18,0x6C36,
	0x0666,0x7676,0xDFD8,0x3C3C,0x6600,0x0010,0x7AB1,0xB951,
	0x6666,0x6E0C,0x1E0C,0x660C,0x0636,0x6600,0x0606,0x660C,
	0x3636,0x060E,0x360C,0xD66C,0x0C06,0x6606,0x0C66,0xC6EF,
	0xC866,0x606C,0x306C,0x6C18,0x6666,0x66CC,0x54D6,0x6066,
	0x0018,0x300C,0x18D8,0x0032,0x0000,0x18D8,0x6C7C,0x7800,
	0x0024,0x66F6,0x6F99,0xF3C3,0x70C3,0x1070,0x181E,0x1998,
	0xC606,0xC006,0x0606,0xC606,0xC606,0x6618,0x1004,0x2E10,
	0x0000,0x00FE,0x7C66,0xCC00,0x1C38,0x6618,0x3000,0x1860,
	0x6618,0x3066,0x0C66,0x6630,0x660C,0x1818,0x0C7E,0x3000,
	0x6066,0x6666,0x6C60,0x6066,0x6618,0x666C,0x60C6,0x6666,
	0x606C,0x6666,0x1866,0x3CEE,0x6618,0x6018,0x0618,0x0000,
	0x0066,0x6660,0x6660,0x303E,0x6618,0x186C,0x18C6,0x6666,
	0x6666,0x6006,0x1866,0x3C7C,0x3C3E,0x3018,0x1818,0x0062,
	0x3C66,0x607E,0x667E,0x7E3C,0x6060,0x6018,0x1818,0x7E7E,
	0x60D8,0xD866,0x6666,0x6666,0x3E66,0x663C,0x3018,0x6630,
	0x7E18,0x6666,0x666E,0x3E3C,0x6030,0x0CC3,0xD618,0x366C,
	0x7E66,0x6666,0xD8D8,0x6666,0x6600,0x0010,0x0ABD,0xAD00,
	0xF6F6,0x667E,0x360C,0x660C,0x0636,0x7E00,0x3E0E,0x6E3C,
	0x1C7E,0x7E7E,0x340C,0xFEEC,0x0C06,0x7E06,0x0C3C,0x8266,
	0xDC66,0x606C,0x666C,0x6C18,0x3C66,0x24EC,0x38D6,0x7066,
	0x7E00,0x0000,0x18D8,0x184C,0x0000,0x1870,0x0000,0x0000,
	0x0024,0x3C1C,0x383C,0xE7E7,0x20C3,0x38F0,0x181B,0x799E,
	0x7C06,0x7C7C,0x067C,0x7C06,0x7C7C,0x3C1E,0x1E3C,0x39E0,
	0x0018,0x006C,0x1846,0x7600,0x0E70,0x0000,0x3000,0x1840,
	0x3C7E,0x7E3C,0x0C3C,0x3C30,0x3C38,0x0030,0x0600,0x6018,
	0x3E66,0x7C3C,0x787E,0x603E,0x663C,0x3C66,0x7EC6,0x663C,
	0x6036,0x663C,0x183E,0x18C6,0x6618,0x7E1E,0x0278,0x00FE,
	0x003E,0x7C3C,0x3E3C,0x3006,0x663C,0x1866,0x3CC6,0x663C,
	0x7C3E,0x607C,0x0E3E,0x186C,0x6606,0x7E0E,0x1870,0x007E,
	0x083E,0x3C3E,0x3E3E,0x3E08,0x3C3C,0x3C3C,0x3C3C,0x6666,
	0x7E7E,0xDF3C,0x3C3C,0x3E3E,0x063C,0x3E18,0x7E18,0x7C60,
	0x3E3C,0x3C3E,0x6666,0x0000,0x6630,0x0C86,0x9F18,0x1BD8,
	0x3E3C,0x3C3C,0x7E7F,0x7E7E,0x6600,0x0000,0x0AC3,0xC300,
	0x0606,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0000,0x3000,0x0000,0x0C06,0x0006,0x0CD8,0x0000,
	0x767C,0x606C,0xFE38,0x7F18,0x183C,0x6678,0x307C,0x3E66,
	0x007E,0x7E7E,0x1870,0x1800,0x0000,0x0030,0x0000,0x0000,
	0x003C,0x1818,0x1800,0x0000,0x007E,0x1060,0x0000,0x718E,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x1754,0x3800,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x6000,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0000,0x0000,0x007C,0x0000,0x7000,0x0000,0x0000,
	0x6006,0x0000,0x0000,0x0000,0x007C,0x0000,0x1800,0x0000,
	0x3800,0x0000,0x0000,0x0018,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x7C00,0x0018,0x0000,0x6000,
	0x0000,0x0000,0x0000,0x3C3C,0x3C00,0x000F,0x0618,0x0000,
	0x0000,0x4040,0x0000,0x6666,0x3C00,0x0000,0x0A7E,0x7E00,
	0x1C1C,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,
	0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0070,0x0000,
	0x0060,0xF848,0x0000,0xC010,0x3C00,0x0000,0x6010,0x0000,
	0x0000,0x0000,0x1800,0x0000,0x0000,0x0000,0x0000,0x0000
#endif
};
