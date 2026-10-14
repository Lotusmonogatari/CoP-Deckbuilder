import openpyxl,json,re,collections
F='/root/.claude/uploads/43b619a9-733a-58b4-a1d4-dc6ec42c5209/a32a519a-CoP_Content_Consolidated_Draft_2026-10-13.xlsx'
wb=openpyxl.load_workbook(F,read_only=True)
def table(n, hdr_first=None):
    rs=[r for r in wb[n].iter_rows(values_only=True) if any(c is not None for c in r)]
    # header = first row whose first cell isn't a long note
    i=0
    while i<len(rs) and (rs[i][0] is None or len(str(rs[i][0]))>40): i+=1
    h=list(rs[i]); out=[]
    for r in rs[i+1:]:
        out.append({k:v for k,v in zip(h,r) if k is not None})
    return h,out
def master(name):
    d=json.load(open(f'/home/user/CoP-Deckbuilder/data/{name}.json'))
    return d.get('rows',d) if isinstance(d,dict) and 'rows' in d else d
