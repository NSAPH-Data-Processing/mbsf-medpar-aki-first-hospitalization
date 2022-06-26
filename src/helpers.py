import json

def get_outcomes(path=None):
    """ Get and return ICD codes """""
    #if path is None:
    read_path = 'src/icd_codes.json'
    read_path_diab = "src/icd10-diabetes.txt"
    #else:
    #    read_path = path+'/icd_codes.json'
    #    read_path_diab = path+"/icd10-diabetes.txt"
    f = open(read_path)
    res_dict = json.load(f)
    f.close()
    res_dict = json.loads(res_dict[0])
    
    f=open(read_path_diab)
    idc10_diab = f.read().split(',')
    f.close()
    res_dict['diabetes']['icd10'] = idc10_diab
    
    return res_dict
