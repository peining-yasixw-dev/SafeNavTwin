using UnityEngine;
using System.IO;

public class RayLogger : MonoBehaviour
{
    string path;

    void Start()
    {
        path = Application.dataPath + "/raydata.csv";
        File.WriteAllText(path, "time,distance\n");
    }

    void Update()
    {
        Ray ray = new Ray(transform.position, transform.forward);
        RaycastHit hit;

        if (Physics.Raycast(ray, out hit, 10f))
        {
            float d = hit.distance;
            string line = Time.time + "," + d + "\n";
            File.AppendAllText(path, line);
        }
    }
}

