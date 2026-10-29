"""Raw-XML workbook editor (no openpyxl save). Works on one .xlsx path."""
import zipfile, re, shutil
from html import unescape
from xml.sax.saxutils import escape

def col2n(c):
    n=0
    for ch in c: n=n*26+ord(ch)-64
    return n
def n2col(n):
    s=''
    while n: n,r=divmod(n-1,26); s=chr(65+r)+s
    return s
CELL=re.compile(r'<c r="([A-Z]+)(\d+)"([^>]*?)(?:/>|>(.*?)</c>)',re.S)

class WB:
    def __init__(self,path):
        self.path=path
        z=zipfile.ZipFile(path); self.infos=z.infolist(); self.files={i.filename:z.read(i.filename) for i in self.infos}
        wbx=self.files['xl/workbook.xml'].decode(); rels=self.files['xl/_rels/workbook.xml.rels'].decode()
        rid={m.group(1):m.group(2) for m in re.finditer(r'Id="(rId\d+)"[^>]*Target="([^"]+)"',rels)}
        rid.update({m.group(2):m.group(1) for m in re.finditer(r'Target="([^"]+)"[^>]*Id="(rId\d+)"',rels)})
        self.sheet={unescape(m.group(1)):'xl/'+rid[m.group(2)].lstrip('/').replace('xl/','') for m in re.finditer(r'<sheet name="([^"]+)"[^>]*r:id="(rId\d+)"',wbx)}
        ss=self.files['xl/sharedStrings.xml'].decode()
        self.ss=[unescape(re.sub(r'<[^>]+>','',m)) for m in re.findall(r'<si>(.*?)</si>',ss,re.S)]
    def save(self,out=None):
        out=out or self.path
        self._drop_calc_chain()
        zo=zipfile.ZipFile(out+'.tmp','w',zipfile.ZIP_DEFLATED)
        for it in self.infos:
            if it.filename in self.files: zo.writestr(it,self.files[it.filename])
        zo.close(); shutil.move(out+'.tmp',out)
    def _drop_calc_chain(self):
        """calcChain.xml is only a cache of which cells hold formulas. After an edit
        it can name cells that no longer have one, and Excel then reports "Removed
        Records: Formula from /xl/calcChain.xml". Without it Excel rebuilds the
        chain silently, so it is dropped on every save."""
        name='xl/calcChain.xml'
        if name not in self.files: return
        del self.files[name]
        rels='xl/_rels/workbook.xml.rels'
        if rels in self.files:
            self.files[rels]=re.sub(rb'<Relationship [^>]*calcChain[^>]*/>',b'',self.files[rels])
        ct='[Content_Types].xml'
        if ct in self.files:
            self.files[ct]=re.sub(rb'<Override [^>]*calcChain[^>]*/>',b'',self.files[ct])
    # ---- reading
    def _x(self,name): return self.files[self.sheet[name]].decode()
    def text(self,attrs,body):
        body=body or ''
        if 't="s"' in attrs:
            m=re.search(r'<v>(\d+)</v>',body); return self.ss[int(m.group(1))] if m else None
        if 'inlineStr' in attrs: return unescape(re.sub(r'<[^>]+>','',body))
        m=re.search(r'<v>(.*?)</v>',body)
        return unescape(m.group(1)) if m else None
    def rows(self,name):
        """{rownum: {col: text}}"""
        x=self._x(name); out={}
        for rm in re.finditer(r'<row r="(\d+)"[^>]*?(?:/>|>(.*?)</row>)',x,re.S):
            d={}
            for c in CELL.finditer(rm.group(2) or ''):
                t=self.text(c.group(3),c.group(4))
                if t not in (None,''): d[c.group(1)]=t
            out[int(rm.group(1))]=d
        return out
    def last_data_row(self,name,col='A'):
        r=self.rows(name); return max([k for k,v in r.items() if col in v] or [0])
    def find_row(self,name,key,col='A'):
        for k,v in self.rows(name).items():
            if v.get(col)==key: return k
        raise KeyError((name,key))
    # ---- writing
    @staticmethod
    def cellxml(ref,value,style='',formula=None):
        if formula is not None:
            v=value
            if isinstance(v,str): return f'<c r="{ref}"{style} t="str"><f>{escape(formula)}</f><v>{escape(v)}</v></c>'
            return f'<c r="{ref}"{style}><f>{escape(formula)}</f><v>{v}</v></c>'
        if value is None: return f'<c r="{ref}"{style}/>'
        if isinstance(value,(int,float)): return f'<c r="{ref}"{style}><v>{value}</v></c>'
        return f'<c r="{ref}"{style} t="inlineStr"><is><t xml:space="preserve">{escape(value)}</t></is></c>'
    def sty(self,name,ref):
        m=re.search(r'<c r="%s"([^>]*?)(?:/>|>)'%ref,self._x(name)); s=re.search(r' s="\d+"',m.group(1)) if m else None
        return s.group(0) if s else ''
    def set_cell(self,name,rownum,col,value,formula=None,style=None,style_from=None):
        p=self.sheet[name]; x=self.files[p].decode()
        rm=re.search(r'<row r="%d"([^>]*?)(/>|>(.*?)</row>)'%rownum,x,re.S)
        cells={}
        if rm:
            attrs=re.sub(r' spans="[^"]*"','',rm.group(1)); inner=rm.group(3) or ''
            for c in CELL.finditer(inner): cells[c.group(1)]=c.group(0)
        else:
            attrs=''
        if style is None:
            if col in cells:
                m=re.search(r' s="\d+"',cells[col]); style=m.group(0) if m else ''
            elif style_from:
                m=re.search(r'<c r="%s%d"([^>]*?)(?:/>|>)'%(col,style_from),x); 
                s2=re.search(r' s="\d+"',m.group(1)) if m else None; style=s2.group(0) if s2 else ''
            else: style=''
        cells[col]=self.cellxml(f'{col}{rownum}',value,style,formula)
        newrow=f'<row r="{rownum}"{attrs}>'+''.join(cells[k] for k in sorted(cells,key=col2n))+'</row>'
        if rm: x=x[:rm.start()]+newrow+x[rm.end():]
        else:
            # insert in row order
            pos=None
            for m in re.finditer(r'<row r="(\d+)"',x):
                if int(m.group(1))>rownum: pos=m.start(); break
            if pos is None: pos=x.index('</sheetData>')
            x=x[:pos]+newrow+x[pos:]
        # dimension
        dm=re.search(r'<dimension ref="A1:([A-Z]+)(\d+)"/>',x)
        if dm:
            mc=max(col2n(dm.group(1)),col2n(col)); mr=max(int(dm.group(2)),rownum)
            x=x.replace(dm.group(0),f'<dimension ref="A1:{n2col(mc)}{mr}"/>')
        self.files[p]=x.encode()
    def typed_row(self,name,rownum):
        """{col: value} for one row with real types: numbers come back as int or
        float, text as str, and a formula cell as its last calculated value
        (the formula itself is not carried). Blank cells are left out."""
        x=self._x(name); rm=re.search(r'<row r="%d"[^>]*?(?:/>|>(.*?)</row>)'%rownum,x,re.S)
        out={}
        for c in CELL.finditer(rm.group(1) or '') if rm else []:
            attrs,body=c.group(3),c.group(4) or ''
            text=self.text(attrs,body)
            if text in (None,''): continue
            is_text='t="s"' in attrs or 'inlineStr' in attrs or 't="str"' in attrs or 't="b"' in attrs
            if is_text: out[c.group(1)]=text; continue
            try:
                f=float(text); out[c.group(1)]=int(f) if f==int(f) and 'e' not in text.lower() and '.' not in text else f
            except ValueError:
                out[c.group(1)]=text
        return out
    def copy_row(self,name,from_key,overrides=None,keycol='A'):
        """Appends a copy of the row whose key (column A unless keycol says
        otherwise) is `from_key`, and returns the new row number.

        Types are kept (numbers stay numbers, which a plain rows()/append_row
        round trip would turn into text) and formulas are replaced by their
        plain values, because hand-copied shared formulas are what makes Excel
        ask to repair the file. `overrides` maps a column letter OR the header
        text from row 1 to the new value; a value of None blanks the cell. A new
        key must be given for the key column or the copy would duplicate the
        original. Nothing is written until save()."""
        src=self.typed_row(name,self.find_row(name,from_key,keycol))
        headers=self.rows(name).get(1,{})
        by_header={v:k for k,v in headers.items()}
        for k,v in (overrides or {}).items():
            col=k if k in headers or re.fullmatch(r'[A-Z]+',k) else by_header.get(k)
            if col is None: raise KeyError((name,k))
            if v is None: src.pop(col,None)
            else: src[col]=v
        if src.get(keycol)==from_key:
            raise ValueError("copy_row needs a new value for column %s (it still holds %r)"%(keycol,from_key))
        return self.append_row(name,src,style_row=self.find_row(name,from_key,keycol),keycol=keycol)
    def append_row(self,name,values,style_row=None,keycol='A'):
        """values: {col: value or (value, formula)}; returns row number."""
        r=self.last_data_row(name,keycol)+1
        sr=style_row or (r-1)
        kw={'style':''} if r<=2 else {'style_from':sr}
        for col,v in values.items():
            if isinstance(v,tuple): self.set_cell(name,r,col,v[0],formula=v[1],**kw)
            else: self.set_cell(name,r,col,v,**kw)
        return r

    def delete_row(self,name,rownum):
        """Removes one row and moves every row below it up by one (2026-10-28).
        Refuses a sheet that has formulas, merged cells, conditional formats,
        data validations or hyperlinks, because their cell references would
        need rewriting too; those sheets need a hand edit. Text, Cards and the
        other plain data tabs are fine. Nothing is written until save()."""
        p=self.sheet[name]; x=self.files[p].decode()
        for tag in ('<f>','<f ','<mergeCell','<conditionalFormatting','<dataValidation','<hyperlink'):
            if tag in x:
                raise ValueError("%s has %s; delete_row cannot shift it safely" % (name,tag))
        rm=re.search(r'<row r="%d"[^>]*?(?:/>|>.*?</row>)'%rownum,x,re.S)
        if not rm: raise KeyError((name,rownum))
        x=x[:rm.start()]+x[rm.end():]
        def shift_row(m):
            n=int(m.group(1))
            if n<=rownum: return m.group(0)
            body=re.sub(r'(<c r="[A-Z]+)(\d+)"',lambda c:'%s%d"'%(c.group(1),int(c.group(2))-1),m.group(0))
            return body.replace('<row r="%d"'%n,'<row r="%d"'%(n-1),1)
        x=re.sub(r'<row r="(\d+)"[^>]*?(?:/>|>.*?</row>)',shift_row,x,flags=re.S)
        dm=re.search(r'<dimension ref="A1:([A-Z]+)(\d+)"/>',x)
        if dm and int(dm.group(2))>1:
            x=x.replace(dm.group(0),'<dimension ref="A1:%s%d"/>'%(dm.group(1),int(dm.group(2))-1))
        self.files[p]=x.encode()


def add_sheet(path, name, headers, rows, widths=None):
    """Appends a whole new worksheet (inline strings only, sharedStrings.xml
    untouched). `rows` is a list of lists; numbers stay numbers. Used for
    Standing Links (2026-10-18)."""
    z = zipfile.ZipFile(path)
    infos = z.infolist()
    files = {i.filename: z.read(i.filename) for i in infos}
    z.close()
    nums = [int(m) for n in files for m in re.findall(r'^xl/worksheets/sheet(\d+)\.xml$', n)]
    n = max(nums) + 1
    wbx = files['xl/workbook.xml'].decode()
    rels = files['xl/_rels/workbook.xml.rels'].decode()
    ct = files['[Content_Types].xml'].decode()
    sheet_id = max(int(m) for m in re.findall(r'sheetId="(\d+)"', wbx)) + 1
    rid = 'rId%d' % (max(int(m) for m in re.findall(r'Id="rId(\d+)"', rels)) + 1)
    wbx = wbx.replace('</sheets>', '<sheet name="%s" sheetId="%d" r:id="%s"/></sheets>' % (escape(name), sheet_id, rid))
    rels = rels.replace('</Relationships>', '<Relationship Id="%s" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet%d.xml"/></Relationships>' % (rid, n))
    ct = ct.replace('</Types>', '<Override PartName="/xl/worksheets/sheet%d.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>' % n)

    def cell(ref, v):
        if v is None or v == '':
            return ''
        if isinstance(v, (int, float)):
            return '<c r="%s"><v>%s</v></c>' % (ref, v)
        return '<c r="%s" t="inlineStr"><is><t xml:space="preserve">%s</t></is></c>' % (ref, escape(str(v)))
    body = ''
    for r, row in enumerate([headers] + rows, start=1):
        body += '<row r="%d">%s</row>' % (r, ''.join(cell(n2col(c) + str(r), v) for c, v in enumerate(row, start=1)))
    widths = widths or [12] * len(headers)
    cols = ''.join('<col min="%d" max="%d" width="%s" customWidth="1"/>' % (i, i, w) for i, w in enumerate(widths, start=1))
    xml = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
           '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
           'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
           '<dimension ref="A1:%s%d"/><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
           '<sheetFormatPr defaultRowHeight="15"/><cols>%s</cols><sheetData>%s</sheetData></worksheet>'
           % (n2col(len(headers)), len(rows) + 1, cols, body))
    files['xl/workbook.xml'] = wbx.encode()
    files['xl/_rels/workbook.xml.rels'] = rels.encode()
    files['[Content_Types].xml'] = ct.encode()
    files['xl/worksheets/sheet%d.xml' % n] = xml.encode()
    zo = zipfile.ZipFile(path + '.tmp', 'w', zipfile.ZIP_DEFLATED)
    for it in infos:
        zo.writestr(it, files[it.filename])
    zo.writestr('xl/worksheets/sheet%d.xml' % n, files['xl/worksheets/sheet%d.xml' % n])
    zo.close()
    shutil.move(path + '.tmp', path)


def replace_sheet_data(path, name, headers, rows):
    """Rewrites every row of an existing sheet made by add_sheet() (header plus
    `rows`, inline strings), keeping its columns and view. Used when a tab built
    earlier is regenerated wholesale (Patron Bills library, 2026-10-19)."""
    w = WB(path)
    p = w.sheet[name]
    x = w.files[p].decode()

    def cell(ref, v):
        if v is None or v == '':
            return ''
        if isinstance(v, (int, float)):
            return '<c r="%s"><v>%s</v></c>' % (ref, v)
        return '<c r="%s" t="inlineStr"><is><t xml:space="preserve">%s</t></is></c>' % (ref, escape(str(v)))
    body = ''
    for r, row in enumerate([headers] + rows, start=1):
        body += '<row r="%d">%s</row>' % (r, ''.join(cell(n2col(c) + str(r), v) for c, v in enumerate(row, start=1)))
    x = re.sub(r'<sheetData>.*</sheetData>', lambda m: '<sheetData>%s</sheetData>' % body, x, flags=re.S)
    x = re.sub(r'<dimension ref="[^"]*"/>', '<dimension ref="A1:%s%d"/>' % (n2col(len(headers)), len(rows) + 1), x)
    w.files[p] = x.encode()
    w.save()
