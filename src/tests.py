import unittest
import pandas as pd
from pandas.testing import assert_series_equal
from final_aggregation import denom, get_outcomes, hospitalized, reset_hospitalized

mbsf = pd.DataFrame({
        "race": [1, 2, 2, 1],
        "zip": [1, 2, 2, 2],
        "year": ["2011", "2011", "2012", "2012"],
        "dual": [0, 0, 0, 0],
        "follow_up": [0, 0, 0, 0],
        "entry_age_group": [0, 0, 0, 0],
        "sex": [0, 0, 0, 0],
        "ids": ["1, 2, 3, 4", "1, 2, 3, 4", "1, 2, 3, 4", "1, 2, 3, 4"],
    })
df = pd.DataFrame({
        "ID": ["1", "2", "3", "4", "2", "3", "3"],
        "race": [1, 1, 1, 2, 2, 2, 2],
        "zip": [1, 1, 2, 2, 2, 2, 2],
        "dual": [0, 0, 0, 0, 0, 0, 0],
        "follow_up": [0, 0, 0, 0, 0, 0, 0],
        "entry_age_group": [0, 0, 0, 0, 0, 0, 0],
        "sex": [0, 0, 0, 0, 0, 0, 0],
        "year": ["2011", "2011", "2012", "2012", "2011", "2012", "2011"],
        "diag": [True, True, True, True, False, True, True]
    })


class FinalAggTest(unittest.TestCase):
    def test_get_outcome(self):
        outcomes = get_outcomes()
        self.assertTrue(pd.api.types.is_dict_like(outcomes))

    def test_group_list(self):
        df = pd.DataFrame({
            "ID": ["1", "2", "3", "4", "2", "3", "3"],
            "race": [1, 1, 1, 2, 2, 2, 2],
            "zip": [1, 1, 2, 2, 2, 2, 2],
            "year": ["2011", "2011", "2012", "2012", "2011", "2012", "2011"],
            "diag": [True, True, True, True, False, True, True]
        })
        hosp = df[df['diag'] == True].groupby(["race", "zip", "year"])['ID'].apply(list)
        group = (1, 1, "2011")
        l1 = hosp.loc(axis=0)[group]
        l2 = ['1', '2']
        self.assertEqual(l1, l2)

    def test_denom(self):
        hosp = df[df['diag'] == True].groupby(
            ["year", "sex", "race", "zip", "dual", "follow_up", "entry_age_group"])['ID'].apply(list)
        mbsf['denom'] = mbsf.apply(denom, hosp=hosp, axis=1)
        res1 = mbsf['denom']
        res2 = pd.Series([2, 1, 0, 0], name='denom')
        assert_series_equal(res1, res2)

    def test_denom_false(self):
        reset_hospitalized()
        hosp = df[df['diag'] == False].groupby(
            ["year", "sex", "race", "zip", "dual", "follow_up", "entry_age_group"])['ID'].apply(list)
        mbsf['denom2'] = mbsf.apply(denom, hosp=hosp, axis=1)
        res = pd.Series([4, 3, 3, 3], name='denom2')
        assert_series_equal(mbsf['denom2'], res)

    def test_empty_hosp(self):
        reset_hospitalized()
        s = len(hospitalized)
        self.assertEqual(s, 0)


if __name__ == '__main__':
    unittest.main()
